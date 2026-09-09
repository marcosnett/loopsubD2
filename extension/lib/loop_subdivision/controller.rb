module LoopSubdivision
  class Controller
    DICT = 'LoopSubdivision'
    ROLE = 'role'
    ROLE_CONTROL = 'control'
    ROLE_SURFACE = 'surface'
    VERSION = 8
    NAME = 'Loop Subdivision Surface'

    class << self
      def install_menu
        commands = command_set
        menu = UI.menu('Tools').add_submenu('Loop Subdivision')
        menu.add_item(commands[:create])
        menu.add_item(commands[:update])
        menu.add_item(commands[:level])
        menu.add_separator
        menu.add_item(commands[:edit])
        menu.add_item(commands[:show])
        menu.add_item(commands[:hide])
        menu.add_item(commands[:auto])
        menu.add_separator
        menu.add_item(commands[:crease_add])
        menu.add_item(commands[:crease_remove])
        menu.add_item(commands[:crease_clear])
        menu.add_separator
        menu.add_item(commands[:remove])

        UI.add_context_menu_handler do |context_menu|
          cage = selected_cage
          next unless cage
          submenu = context_menu.add_submenu('Loop Subdivision')
          submenu.add_item(commands[:edit])
          submenu.add_item(commands[:update])
          submenu.add_item(commands[:level])
          submenu.add_separator
          submenu.add_item(commands[:show])
          submenu.add_item(commands[:hide])
          submenu.add_item(commands[:auto])
          submenu.add_separator
          submenu.add_item(commands[:crease_add])
          submenu.add_item(commands[:crease_remove])
          submenu.add_item(commands[:crease_clear])
          submenu.add_separator
          submenu.add_item(commands[:remove])
        end
      end

      # Creates the same UI::Command objects used by the menu, context menu
      # and toolbar. Keeping one command object per action makes the toolbar
      # only another access point to the existing functionality.
      def command_set
        return @commands if @commands

        @commands = {}
        @commands[:create] = make_command('Create Subdivision') { create }
        @commands[:update] = make_command('Update Subdivision') { update_selected }
        @commands[:level]  = make_command('Subdivision Level') { set_level_selected }
        @commands[:edit]   = make_command('Edit Control Cage') { edit_control_selected }
        @commands[:show]   = make_command('Show Control Cage') { show_control_selected }
        @commands[:hide]   = make_command('Hide Control Cage') { hide_control_selected }
        @commands[:auto]   = make_command('Auto Update') { toggle_auto_update_selected }
        @commands[:crease_add] = make_command('Add Crease') { Crease.add_selected }
        @commands[:crease_remove] = make_command('Remove Crease') { Crease.remove_selected }
        @commands[:crease_clear] = make_command('Clear Creases') { Crease.clear_selected_cage }
        @commands[:remove] = make_command('Remove Subdivision') { remove_selected }
        @commands
      end

      def make_command(name, icon_name = nil, &block)
        command = UI::Command.new(name, &block)
        command.tooltip = name
        command.status_bar_text = name
        if icon_name
          root = File.expand_path('../..', File.dirname(__FILE__))
          small = File.join(root, 'icons', icon_name + '_24.png')
          large = File.join(root, 'icons', icon_name + '_32.png')
          command.small_icon = small if File.exist?(small)
          command.large_icon = large if File.exist?(large)
        end
        command
      end

      def install_toolbar
        return if @toolbar

        commands = command_set
        @toolbar = UI::Toolbar.new('Loop Subdivision')
        @toolbar.add_item(icon_command(commands[:create], 'create'))
        @toolbar.add_item(icon_command(commands[:update], 'update'))
        @toolbar.add_item(icon_command(commands[:level], 'level'))
        @toolbar.add_separator
        @toolbar.add_item(icon_command(commands[:edit], 'edit'))
        @toolbar.add_item(icon_command(commands[:show], 'show'))
        @toolbar.add_item(icon_command(commands[:hide], 'hide'))
        @toolbar.add_item(icon_command(commands[:auto], 'auto'))
        @toolbar.add_separator
        @toolbar.add_item(icon_command(commands[:crease_add], 'crease'))
        @toolbar.show
      end

      def icon_command(command, icon_name)
        root = File.expand_path('../..', File.dirname(__FILE__))
        small = File.join(root, 'icons', icon_name + '_24.png')
        large = File.join(root, 'icons', icon_name + '_32.png')
        command.small_icon = small if File.exist?(small)
        command.large_icon = large if File.exist?(large)
        command
      end

      def create
        model = Sketchup.active_model
        selection = model.selection.to_a
        if selection.empty?
          UI.messagebox('Selecione a geometria que deseja usar como malha de controle.')
          return
        end
        if selection.any? { |e| subdivision_entity?(e) }
          UI.messagebox('A seleção já pertence a uma subdivisão.')
          return
        end

        model.start_operation('Create Loop Subdivision Surface', true)
        begin
          cage = model.entities.add_group(selection)
          cage.name = 'Control Cage'
          cage.set_attribute(DICT, ROLE, ROLE_CONTROL)
          cage.set_attribute(DICT, 'version', VERSION)
          cage.set_attribute(DICT, 'level', 1)
          cage.set_attribute(DICT, 'soften', true)
          cage.set_attribute(DICT, 'auto_update', true)
          cage.set_attribute(DICT, 'cage_hidden', true)

          surface = build_surface(cage)
          cage.set_attribute(DICT, 'surface_pid', surface.persistent_id)
          surface.set_attribute(DICT, 'control_pid', cage.persistent_id)
          surface.set_attribute(DICT, 'version', VERSION)

          cage.hidden = true
          surface.hidden = false
          model.selection.clear
          model.selection.add(surface)
          model.commit_operation
        rescue => e
          model.abort_operation
          UI.messagebox("Não foi possível criar a subdivisão:\n#{e.class}: #{e.message}")
          puts e.message
          puts e.backtrace.join("\n")
        end
      end

      def update_selected
        cages = selected_cages
        return UI.messagebox('Selecione a malha de controle ou a superfície de uma subdivisão.') if cages.empty?
        model = Sketchup.active_model
        model.start_operation('Update Loop Subdivision Surface', true)
        begin
          cages.each { |cage| rebuild(cage) }
          model.commit_operation
        rescue => e
          model.abort_operation
          UI.messagebox("Falha ao atualizar:\n#{e.class}: #{e.message}")
          puts e.message
          puts e.backtrace.join("\n")
        end
      end

      def set_level_selected
        cages = selected_cages
        return UI.messagebox('Selecione a malha de controle ou a superfície de uma subdivisão.') if cages.empty?
        current = cages.first.get_attribute(DICT, 'level', 1).to_i
        result = UI.inputbox(['Nível de subdivisão (0–4):'], [current], 'Loop Subdivision')
        return unless result
        level = [[result[0].to_i, 0].max, 4].min
        model = Sketchup.active_model
        model.start_operation('Change Subdivision Level', true)
        begin
          cages.each do |cage|
            cage.set_attribute(DICT, 'level', level)
            rebuild(cage)
          end
          model.commit_operation
        rescue => e
          model.abort_operation
          UI.messagebox("Falha ao alterar o nível:\n#{e.class}: #{e.message}")
          puts e.message
          puts e.backtrace.join("\n")
        end
      end

      def edit_control_selected
        cage = selected_cage
        return UI.messagebox('Selecione a malha de controle ou a superfície de uma subdivisão.') unless cage
        model = Sketchup.active_model
        surface = surface_for(cage)
        cage.hidden = false
        cage.set_attribute(DICT, 'cage_hidden', false)
        cage.set_attribute(DICT, 'editing_cage', true)
        cage.set_attribute(DICT, 'hide_after_edit', true)
        model.selection.clear
        model.selection.add(cage)

        begin
          # Cage is a root-level group, so this is a valid one-element edit path
          # on SketchUp 2020+ and does not depend on nested controller paths.
          model.active_path = [cage]
          Crease.apply_display(cage)
          model.active_view.refresh
        rescue => e
          Crease.restore_display(cage)
          cage.set_attribute(DICT, 'editing_cage', false)
          cage.set_attribute(DICT, 'hide_after_edit', false)
          UI.messagebox("Não foi possível abrir a malha de controle para edição:\n#{e.class}: #{e.message}")
          puts e.message
          puts e.backtrace.join("\n")
        end
      end

      def show_control_selected
        cages = selected_cages
        return UI.messagebox('Selecione a malha de controle ou a superfície de uma subdivisão.') if cages.empty?
        cages.each do |cage|
          cage.hidden = false
          cage.set_attribute(DICT, 'cage_hidden', false)
          cage.set_attribute(DICT, 'hide_after_edit', false)
          Crease.apply_display(cage)
        end
        Sketchup.active_model.active_view.refresh
      end

      def hide_control_selected
        cages = selected_cages
        return UI.messagebox('Selecione a malha de controle ou a superfície de uma subdivisão.') if cages.empty?
        model = Sketchup.active_model
        if model.active_path && cages.any? { |c| model.active_path.include?(c) }
          UI.messagebox('Feche a edição da malha de controle antes de ocultá-la.')
          return
        end
        cages.each do |cage|
          Crease.restore_display(cage)
          cage.hidden = true
          cage.set_attribute(DICT, 'cage_hidden', true)
          cage.set_attribute(DICT, 'hide_after_edit', false)
        end
        model.active_view.refresh
      end

      def toggle_auto_update_selected
        cages = selected_cages
        return UI.messagebox('Selecione a malha de controle ou a superfície de uma subdivisão.') if cages.empty?
        cages.each do |cage|
          current = cage.get_attribute(DICT, 'auto_update', true)
          cage.set_attribute(DICT, 'auto_update', !current)
        end
        state = cages.first.get_attribute(DICT, 'auto_update', true) ? 'ATIVADA' : 'DESATIVADA'
        UI.messagebox("Atualização automática: #{state}.")
      end

      def remove_selected
        cages = selected_cages
        return UI.messagebox('Selecione a malha de controle ou a superfície de uma subdivisão.') if cages.empty?
        model = Sketchup.active_model
        if model.active_path && cages.any? { |c| model.active_path.include?(c) }
          UI.messagebox('Feche a edição da malha de controle antes de remover a subdivisão.')
          return
        end
        model.start_operation('Remove Loop Subdivision', true)
        begin
          cages.each do |cage|
            surface = surface_for(cage)
            surface.erase! if surface && !surface.deleted?
            cage.hidden = false
            cage.delete_attribute(DICT, 'surface_pid')
            cage.delete_attribute(DICT, 'role')
            cage.name = 'Control Cage'
          end
          model.commit_operation
        rescue => e
          model.abort_operation
          UI.messagebox("Falha ao remover a subdivisão:\n#{e.class}: #{e.message}")
          puts e.message
          puts e.backtrace.join("\n")
        end
      end

      def control?(entity)
        entity.is_a?(Sketchup::Group) && entity.get_attribute(DICT, ROLE) == ROLE_CONTROL
      end

      def surface?(entity)
        entity.is_a?(Sketchup::Group) && entity.get_attribute(DICT, ROLE) == ROLE_SURFACE
      end

      def subdivision_entity?(entity)
        control?(entity) || surface?(entity)
      end

      def selected_cages
        cages = []
        Sketchup.active_model.selection.to_a.each do |entity|
          cage = cage_for(entity)
          cages << cage if cage && !cage.deleted? && !cages.include?(cage)
        end
        cages
      end

      def selected_cage
        selected_cages.first
      end

      def cage_for(entity)
        return entity if control?(entity)
        if entity.is_a?(Sketchup::Group) && entity.get_attribute(DICT, ROLE) == 'controller'
          return migrate_legacy_controller(entity)
        end
        return nil unless surface?(entity)
        pid = entity.get_attribute(DICT, 'control_pid')
        find_root_group_by_pid(pid)
      end

      def surface_for(cage)
        pid = cage.get_attribute(DICT, 'surface_pid')
        find_root_group_by_pid(pid)
      end

      def find_root_group_by_pid(pid)
        return nil if pid.nil?
        Sketchup.active_model.entities.each do |entity|
          if entity.is_a?(Sketchup::Group) && entity.persistent_id == pid
            return entity
          end
        end
        nil
      end

      def build_surface(cage)
        mesh = Core.extract(cage.entities)
        raise 'A malha de controle não contém faces trianguláveis.' if mesh.faces.empty?
        level = cage.get_attribute(DICT, 'level', 1).to_i
        result = Core.subdivide_repeated(mesh, level)
        surface = Sketchup.active_model.entities.add_group
        surface.name = 'Subdivision Surface'
        surface.set_attribute(DICT, ROLE, ROLE_SURFACE)
        surface.set_attribute(DICT, 'generated', true)
        add_mesh(surface.entities, result)
        soften(surface) if cage.get_attribute(DICT, 'soften', true)
        surface
      end

      def rebuild(cage)
        surface = surface_for(cage)
        surface.erase! if surface && !surface.deleted?
        surface = build_surface(cage)
        cage.set_attribute(DICT, 'surface_pid', surface.persistent_id)
        surface.set_attribute(DICT, 'control_pid', cage.persistent_id)
        surface.set_attribute(DICT, 'version', VERSION)
        surface.hidden = false
        cage.hidden = cage.get_attribute(DICT, 'cage_hidden', true)
        cage.set_attribute(DICT, 'signature', signature(cage))
        surface
      end

      def add_mesh(entities, mesh)
        mesh.faces.each do |face|
          pts = face.v.map { |i| mesh.vertices[i].to_a }
          f = entities.add_face(pts)
          next unless f
          f.material = face.material if face.material
          f.back_material = face.back_material if face.back_material
        end
      end

      def soften(surface)
        surface.entities.grep(Sketchup::Edge).each do |edge|
          edge.soft = true
          edge.smooth = true
        end
      end

      def signature(cage)
        rows = []
        visit = lambda do |entities|
          entities.each do |e|
            case e
            when Sketchup::Group
              visit.call(e.entities) unless surface?(e)
            when Sketchup::ComponentInstance
              visit.call(e.definition.entities)
            when Sketchup::Face
              ids = e.vertices.map(&:persistent_id).sort.join(',')
              pts = e.vertices.map { |v| [v.position.x.round(5), v.position.y.round(5), v.position.z.round(5)] }.sort.flatten.join(',')
              rows << "F:#{ids}:#{pts}"
            when Sketchup::Edge
              if e.get_attribute(DICT, 'crease', false) == true
                a = e.start.position
                b = e.end.position
                p1 = [a.x.round(5), a.y.round(5), a.z.round(5)]
                p2 = [b.x.round(5), b.y.round(5), b.z.round(5)]
                ends = [p1, p2].sort.flatten.join(',')
                rows << "C:#{ends}"
              end
            end
          end
        end
        visit.call(cage.entities)
        if defined?(Digest)
          Digest::SHA1.hexdigest(rows.sort.join('|'))
        else
          rows.sort.join('|')
        end
      end

      # Best-effort migration of the v2/v2.2 nested controller.
      # The old controller is exploded one level, leaving its Control Cage and
      # generated Surface as root-level groups. The old surface is discarded.
      def migrate_legacy_controller(old_controller)
        return nil unless old_controller.is_a?(Sketchup::Group)
        return nil unless old_controller.get_attribute(DICT, ROLE) == 'controller'

        model = Sketchup.active_model
        model.start_operation('Migrate Loop Subdivision Controller', true)
        begin
          exploded = old_controller.explode
          cage = exploded.find { |e| control?(e) }
          exploded.each do |e|
            e.erase! if surface?(e) && !e.deleted?
          end
          raise 'A malha de controle antiga não foi encontrada.' unless cage && !cage.deleted?

          cage.name = 'Control Cage'
          cage.set_attribute(DICT, ROLE, ROLE_CONTROL)
          cage.set_attribute(DICT, 'version', VERSION)
          cage.set_attribute(DICT, 'level', old_controller.get_attribute(DICT, 'level', 1).to_i)
          cage.set_attribute(DICT, 'soften', old_controller.get_attribute(DICT, 'soften', true))
          cage.set_attribute(DICT, 'auto_update', old_controller.get_attribute(DICT, 'auto_update', true))
          cage.set_attribute(DICT, 'cage_hidden', true)
          cage.set_attribute(DICT, 'editing_cage', false)
          cage.set_attribute(DICT, 'hide_after_edit', false)

          cage.hidden = true
          rebuild(cage)
          model.selection.clear
          model.selection.add(cage)
          model.commit_operation
          cage
        rescue => e
          model.abort_operation
          puts "LoopSubdivision migration: #{e.class}: #{e.message}"
          puts e.backtrace.join("\n")
          nil
        end
      end
    end
  end
end
