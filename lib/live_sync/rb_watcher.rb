module LiveSync
  class RbWatcher < Watcher

    def watch path, *modes, excludes: [], samefs: true, delay: 1, recursive: true, **params, &block
      raise "#{path}: not a directory" unless File.directory? path
      modes  = DEFAULT_MODES if modes.blank?
      modes << :delete if sync&.delete&.in? [true, :watched]

      tracker = Tracker.new self, path, delay, &block
      rtgts = glob path, recursive: recursive, excludes: excludes
      track(path, rtgts, *modes,
        delay:     1,
        tracker:   tracker,
        recursive: recursive,
        excludes:  excludes,
        samefs:    samefs,
      )
      tracker.timeout_check

      self
    end

    protected

    class Tracker
      def initialize watcher, path, delay, &block
        @watcher  = watcher
        @delay    = delay
        @block    = block
        @to_sync  = Set.new
        @notifier = INotify::Notifier.new
      end

      def watch *args, &block
        @notifier.watch *args, &block
      end

      def track event
        @to_sync << OpenStruct.new(absolute_name: event.absolute_name, flags: event.flags)
      end

      def check
        @notifier.process # calls track
        @watcher.notify @to_sync, &@block
        @to_sync.clear
      ensure
        timeout_check
      end

      def timeout_check
        Thread.new{ sleep @delay; check }
      end
    end

    def track path, rtgts, *modes, tracker:, **opts
      rtgts.each do |rt|
        t = "#{path}/#{rt}"
        tracker.watch t, *modes do |event|
          tracker.track event
          et = event.absolute_name
          next unless opts[:recursive] and File.directory?(et) and :create.in? event.flags
          track et, glob(et, **opts), *modes, tracker: tracker, **opts
        end
      rescue => e
        log&.warning "watcher: #{t}: skipping due to #{e.class}: #{e.message}"
      end
    end

    def glob path, recursive: true, samefs: true, excludes: [], **params
      wcard = if recursive then '{.**,**}/' else '' end
      tgts  = [path] + Dir.glob("#{path}/#{wcard}")

      dev   = File.stat(path).dev
      tgts.select!{ |t| dev == File.stat(t).dev } if samefs

      rtgts = tgts.map{ |t| Pathname.new(t).relative_path_from(path).to_s }
      excs  = excludes.map{ |e| Regexp.new e } || []
      excs.each do |e|
        next unless mt = rtgts.find{ |rt| e.match rt }
        log&.debug "watcher: skipping #{path}/#{mt} with subdirs"
        rtgts.delete mt
        rtgts.delete_if{ |rt| rt.start_with? mt } if File.directory? "#{path}/#{mt}"
      end
      rtgts
    end

  end
end
