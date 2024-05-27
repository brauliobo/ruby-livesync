module LiveSync
  class Watcher

    DEFAULT_MODES = %i[create modify]

    attr_reader :sync
    delegate :log, to: :sync

    def initialize sync=nil
      @sync = sync
    end

    def watch path, *modes, delay: 1, excludes: [], &block
    end

    def notify events, &block
      log.debug "NOTIFY: #{events.inspect}"
      block.call Set.new events
    end

    def watching?
      false
    end

  end
end
