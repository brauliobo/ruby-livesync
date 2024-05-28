module LiveSync
  class Watcher

    DEFAULT_MODES = %i[create modify]

    attr_reader :sync
    delegate :log, to: :sync, allow_nil: true

    def initialize sync=nil
      @sync = sync
    end

    def watch path, *modes, delay: 1, excludes: [], &block
    end

    def notify events, &block
      log&.debug "NOTIFY: #{events.inspect}"
      events.each{ |e| e.flags = e.flags.map{ |f| flag_map f } }
      block.call Set.new events
    end

    def watching?
      false
    end

    def flag_map e
      e
    end

  end
end
