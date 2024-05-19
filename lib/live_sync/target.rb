module LiveSync
  class Target

    include DSL

    attr_reader :sync
    delegate :log, to: :sync

    attr_reader :source, :dest, :path, :userhost
    attr_reader :reverse

    def initialize sync, source, dest, reverse: false, &block
      @sync    = sync
      @source  = source
      @dest    = dest
      @reverse = reverse
      @userhost, @path = if reverse then source else dest end.split ':'
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
