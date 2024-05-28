module LiveSync
  class Target

    include DSL

    attr_reader :sync
    delegate :log, to: :sync

    attr_reader :source, :dest
    attr_reader :userhost, :localpath, :remotepath, :watchpath
    attr_reader :reverse

    delegate :watcher, :modes, :excludes, :delay, to: :sync

    def initialize sync, source, dest, reverse: false, &block
      @sync    = sync
      @source  = source
      @dest    = dest
      @reverse = reverse
      @to_sync = Set.new

      @localpath = if reverse then dest else source end
      @userhost, @remotepath = if reverse then source else dest end.split ':'
      @watchpath = if reverse then @remotepath else @localpath end
      raise "#{sync.ctx}: missing target path" unless @remotepath

      dsl_apply &block if block
    end

    def watch
      watcher.watch watchpath, *modes, excludes: excludes, delay: delay, &method(:on_notify)
    end

    def on_notify events
      wpath = Pathname.new watchpath
      paths = events.map{ |e| Pathname.new(e.absolute_name).relative_path_from(wpath).to_s }
      @to_sync.merge paths
      return if running?
      partial @to_sync
      @to_sync.clear
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
