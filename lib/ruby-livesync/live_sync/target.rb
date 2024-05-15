module LiveSync
  class Target

    include DSL

    attr_reader :sync
    delegate :log, to: :sync

    attr_reader :dest, :path, :userhost

    def initialize sync, dest, &block
      @sync = sync
      @dest = dest
      @userhost, @path = dest.split ':'
      raise "#{sync.ctx}: missing target path" unless @path
      dsl_apply &block if block
    end

    def start
      false
    end

    def running?
      false
    end

    def initial
      raise 'not implemented'
    end

    def partial paths
      raise 'not implemented'
    end

  end
end
