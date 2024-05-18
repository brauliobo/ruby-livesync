module LiveSync
  class Watcher

    DEFAULT_MODES = %i[create modify]

    attr_reader :sync

    def initialize sync=nil
      @sync = sync
    end

    def watch path, *modes, delay: 1, excludes: [], &block
    end

  end
end
