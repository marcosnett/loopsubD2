module LoopSubdivision
  module Observer
    class ModelObserver < Sketchup::ModelObserver
      POLL_INTERVAL = 0.25

      def initialize
        @scheduled = {}
        @updating = {}
        @last_poll = {}
      end

      def onTransactionCommit(model)
        # Transaction callbacks are useful as a fast path, but they are not
        # reliable enough on every SketchUp version to be the sole trigger for
        # Auto Update.  In particular, while a Control Cage is being edited,
        # SketchUp may commit geometry changes before it reports the edit path.
        return if updating?(model)
        schedule_check(model)
      end

      def onActivePathChanged(model)
        # Leaving the Cage is the preferred moment for an automatic rebuild.
        # A short timer also avoids depending on the exact ordering of
        # onActivePathChanged and onTransactionCommit in SketchUp 2020.
        schedule_check(model)
      end

      def start_polling
        return if @poll_timer
        @poll_timer = UI.start_timer(POLL_INTERVAL, true) do
          begin
            model = Sketchup.active_model
            check_model(model) if model
          rescue => e
            puts "LoopSubdivision observer timer: #{e.class}: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
          end
        end
      end

      private

      def updating?(model)
        @updating[model.object_id] == true
      end

      def any_auto_update?(model)
        model.entities.any? do |e|
          Controller.control?(e) && e.get_attribute(Controller::DICT, 'auto_update', true)
        end
      end

      def active_editing_cage?(model)
        path = model.active_path
        return false unless path && !path.empty?
        path.any? { |entity| Controller.control?(entity) }
      end

      def editing_flag?(model)
        model.entities.any? do |e|
          Controller.control?(e) && e.get_attribute(Controller::DICT, 'editing_cage', false)
        end
      end

      def schedule_check(model)
        return unless model
        return if @scheduled[model.object_id]
        @scheduled[model.object_id] = true
        UI.start_timer(0.10, false) do
          @scheduled.delete(model.object_id)
          begin
            check_model(model)
          rescue => e
            puts "LoopSubdivision observer: #{e.class}: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
          end
        end
      end

      def check_model(model)
        return if updating?(model)
        return unless any_auto_update?(model)

        controllers = model.entities.select { |e| Controller.control?(e) }
        return if controllers.empty?

        # Never rebuild while the user is inside a Control Cage.  We want the
        # complete edit (including delete/add edge operations) to finish first.
        if active_editing_cage?(model)
          @last_poll[model.object_id] = Time.now.to_f
          return
        end

        # If the edit flag survived until after the active path was cleared,
        # finalize it here. This makes Auto Update independent of
        # onActivePathChanged reliability in SketchUp 2020.
        restore_after_edit(model) if editing_flag?(model)

        changed = controllers.select do |cage|
          next false unless cage.get_attribute(Controller::DICT, 'auto_update', true)
          current = Controller.signature(cage)
          stored = cage.get_attribute(Controller::DICT, 'signature', '')
          current != stored
        end
        return if changed.empty?

        @updating[model.object_id] = true
        model.start_operation('Auto Update Loop Subdivision Surface', true)
        begin
          changed.each { |cage| Controller.rebuild(cage) }
          model.commit_operation
        rescue => e
          model.abort_operation
          puts "LoopSubdivision auto update: #{e.class}: #{e.message}"
          puts e.backtrace.join("\n") if e.backtrace
        ensure
          @updating.delete(model.object_id)
        end
      end

      def restore_after_edit(model)
        model.entities.each do |entity|
          next unless Controller.control?(entity)
          next unless entity.get_attribute(Controller::DICT, 'editing_cage', false)

          if entity.get_attribute(Controller::DICT, 'hide_after_edit', false)
            Crease.restore_display(entity)
            entity.hidden = true
            entity.set_attribute(Controller::DICT, 'cage_hidden', true)
          else
            Crease.apply_display(entity)
          end
          entity.set_attribute(Controller::DICT, 'editing_cage', false)
          entity.set_attribute(Controller::DICT, 'hide_after_edit', false)
        end
      end
    end

    def self.install
      @observer ||= ModelObserver.new
      Sketchup.add_observer(@observer)
      @observer.start_polling
    end
  end
end
