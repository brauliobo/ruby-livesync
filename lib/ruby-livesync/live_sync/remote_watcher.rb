module LiveSync
  class RemoteWatcher < Watcher

    attr_reader :notifier
    delegate_missing_to :notifier

    attr_reader :sync

    def initialize sync=nil
      @sync     = sync
      @notifier = INotify::Notifier.new
    end

    def watch path, *modes
    end

    def dir_rwatch path, *modes
    end

  end
end
