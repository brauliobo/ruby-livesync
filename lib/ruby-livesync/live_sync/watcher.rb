module LiveSync
  class Watcher

    attr_reader :notifier
    delegate_missing_to :notifier

    attr_reader :sync

    def initialize sync=nil
      @sync     = sync
      @notifier = INotify::Notifier.new
    end

    def watch path, *modes
      Log.debug "#{path}: watching for #{modes.join ','}"
      modes  = %i[all_events] if modes.blank?

      notifier.watch path, *modes do |event|
        yield event
      end
      self
    end

    def dir_rwatch path, *modes
      raise "#{path}: not a directory" unless File.directory? path
      modes  = %i[create modify] if modes.blank?
      modes << :delete if sync&.delete&.in? [true, :watched]

      excs  = sync&.excludes.map{ |e| Regexp.new e } || []
      tgts  = [path] + Dir.glob("#{path}/{.**,**}/")
      rtgts = tgts.map{ |t| Pathname.new(t).relative_path_from(path).to_s }
      excs.each do |e|
        next unless mt = rtgts.find{ |rt| e.match rt }
        Log.debug "watcher: skipping #{path}/#{mt} with subdirs"
        rtgts.delete mt
        rtgts.delete_if{ |rt| rt.start_with? mt } if File.directory? "#{path}/#{mt}"
      end

      rtgts.each do |rt|
        t = "#{path}/#{rt}"
        notifier.watch t, *modes do |event|
          yield event
        end
      rescue => e
        Log.warning "watcher: #{t}: skipping due to #{e.class}: #{e.message}"
      end
      self
    end

  end
end
