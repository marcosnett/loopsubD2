module LoopSubdivision
  module Crease
    DICT = Controller::DICT
    KEY = 'crease'
    DISPLAY_MATERIAL = 'LoopSubdivision_Crease_Display'
    DISPLAY_MATERIAL_COLOR = Sketchup::Color.new(255, 80, 0)
    DISPLAY_MAT_KEY = 'crease_display_original_material'

    module_function

    def crease?(edge)
      edge.is_a?(Sketchup::Edge) && edge.get_attribute(DICT, KEY, false) == true
    end

    def set(edge, value)
      return unless edge.is_a?(Sketchup::Edge)
      edge.set_attribute(DICT, KEY, !!value)
    end

    def selected_edges
      Sketchup.active_model.selection.to_a.grep(Sketchup::Edge)
    end

    def selected_control_edges
      model = Sketchup.active_model
      path = model.active_path
      return [] unless path && !path.empty?
      cage = path.reverse.find { |entity| Controller.control?(entity) }
      return [] unless cage
      selected_edges
    end

    def add_selected
      edges = selected_control_edges
      if edges.empty?
        UI.messagebox('Entre na edição da Control Cage e selecione uma ou mais arestas.')
        return
      end
      model = Sketchup.active_model
      model.start_operation('Add Crease', true)
      begin
        count = 0
        edges.each do |edge|
          unless crease?(edge)
            set(edge, true)
            count += 1
          end
        end
        cage = active_cage
        apply_display(cage) if cage
        model.commit_operation
        model.active_view.refresh
        UI.messagebox("#{count} aresta(s) marcada(s) como Crease.")
      rescue => e
        model.abort_operation
        UI.messagebox("Falha ao marcar Crease:\n#{e.class}: #{e.message}")
      end
    end

    def remove_selected
      edges = selected_control_edges
      if edges.empty?
        UI.messagebox('Entre na edição da Control Cage e selecione uma ou mais arestas.')
        return
      end
      model = Sketchup.active_model
      model.start_operation('Remove Crease', true)
      begin
        count = 0
        edges.each do |edge|
          if crease?(edge)
            set(edge, false)
            count += 1
          end
        end
        cage = active_cage
        apply_display(cage) if cage
        model.commit_operation
        model.active_view.refresh
        UI.messagebox("#{count} aresta(s) desmarcada(s) como Crease.")
      rescue => e
        model.abort_operation
        UI.messagebox("Falha ao remover Crease:\n#{e.class}: #{e.message}")
      end
    end

    def clear_selected_cage
      model = Sketchup.active_model
      cage = active_cage
      unless cage
        UI.messagebox('Entre na edição da Control Cage para limpar as Creases.')
        return
      end
      model.start_operation('Clear Creases', true)
      begin
        count = 0
        cage.entities.each do |entity|
          next unless entity.is_a?(Sketchup::Edge)
          if crease?(entity)
            set(entity, false)
            count += 1
          end
        end
        apply_display(cage)
        model.commit_operation
        model.active_view.refresh
        UI.messagebox("#{count} aresta(s) Crease removida(s) da Control Cage.")
      rescue => e
        model.abort_operation
        UI.messagebox("Falha ao limpar Creases:\n#{e.class}: #{e.message}")
      end
    end

    def count_in_active_cage
      cage = active_cage
      return 0 unless cage
      cage.entities.count { |e| e.is_a?(Sketchup::Edge) && crease?(e) }
    end

    def active_cage
      model = Sketchup.active_model
      path = model.active_path
      return nil unless path && !path.empty?
      path.reverse.find { |entity| Controller.control?(entity) }
    end

    # Applies a temporary material to Crease edges while the Control Cage is
    # visible. The original edge material and edge-color mode are preserved.
    # This uses SketchUp's native edge material display and is compatible with
    # the SketchUp 2020 API.
    def apply_display(cage)
      return unless cage && !cage.deleted?
      model = Sketchup.active_model
      ensure_display_material(model)
      remember_rendering_state(model)
      model.rendering_options['EdgeColorMode'] = 0 # By Material
      model.rendering_options['DisplayColorByLayer'] = false

      cage.entities.each do |entity|
        next unless entity.is_a?(Sketchup::Edge)
        stored = entity.get_attribute(DICT, DISPLAY_MAT_KEY, nil)
        unless crease?(entity)
          restore_edge_material(entity, model) if !stored.nil?
          next
        end
        unless stored
          original = entity.material
          entity.set_attribute(DICT, DISPLAY_MAT_KEY, original ? original.name : '')
        end
        entity.material = display_material(model)
      end
      model.active_view.refresh
    rescue => e
      puts "LoopSubdivision Crease display: #{e.class}: #{e.message}"
    end

    def restore_display(cage)
      return unless cage && !cage.deleted?
      model = Sketchup.active_model
      cage.entities.each do |entity|
        next unless entity.is_a?(Sketchup::Edge)
        stored = entity.get_attribute(DICT, DISPLAY_MAT_KEY, nil)
        next if stored.nil?
        restore_edge_material(entity, model)
      end
      restore_rendering_state(model)
      model.active_view.refresh
    rescue => e
      puts "LoopSubdivision Crease restore: #{e.class}: #{e.message}"
    end

    def restore_edge_material(entity, model)
      stored = entity.get_attribute(DICT, DISPLAY_MAT_KEY, nil)
      return if stored.nil?
      if stored.to_s.empty?
        entity.material = nil
      else
        mat = model.materials[stored.to_s]
        entity.material = mat if mat
      end
      entity.delete_attribute(DICT, DISPLAY_MAT_KEY)
    end

    def ensure_display_material(model)
      mat = model.materials[DISPLAY_MATERIAL]
      unless mat
        mat = model.materials.add(DISPLAY_MATERIAL)
        mat.color = DISPLAY_MATERIAL_COLOR
      end
      mat
    end

    def display_material(model)
      ensure_display_material(model)
    end

    def remember_rendering_state(model)
      key = 'crease_display_rendering_state'
      return if model.get_attribute(DICT, key, nil)
      model.set_attribute(DICT, key, [
        model.rendering_options['EdgeColorMode'],
        model.rendering_options['DisplayColorByLayer']
      ])
    end

    def restore_rendering_state(model)
      key = 'crease_display_rendering_state'
      state = model.get_attribute(DICT, key, nil)
      return unless state.is_a?(Array) && state.length >= 2
      model.rendering_options['EdgeColorMode'] = state[0]
      model.rendering_options['DisplayColorByLayer'] = state[1]
      model.delete_attribute(DICT, key)
    end
  end
end
