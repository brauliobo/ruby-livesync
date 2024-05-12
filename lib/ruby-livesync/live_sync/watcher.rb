module LiveSync
  class Watcher

    attr_reader :notifier
    delegate_missing_to :notifier

    def initialize
      @notifier = INotify::Notifier.new
    end

    def watch path, *modes
      Log.info "#{path}: watching for #{modes.join ','}"
      modes = %i[all_events] if modes.blank?

      notifier.watch path, *modes do |event|
        yield event
      end
      self
    end

    def dir_rwatch path, *modes, excludes: [] 
      raise "#{path}: not a directory" unless File.directory? path
      modes = %i[create modify] if modes.blank?

      excs = excludes.map{ |e| Regexp.new Regexp.quote e }
      tgts = Dir.glob("#{path}/{.**,**}/")
      tgts.each do |t|
        next Log.debug "watcher: skipping #{t}" if excs.any?{ |e| e.match t rescue nil }
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
