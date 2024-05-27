module LiveSync
  class Sync

    include DSL

    attr_reader :name
    attr_reader :log

    def initialize name = nil, &block
      fill_name name
      source name if File.directory? name
      dsl_apply(&block)
    end

    def fill_name name
      return if @name
      self.ctx = @name = name
      @log = Log.new ctx
    end

    dsl :enabled, default: true

    dsl :watcher, default: :rb do |name|
      klass = :"#{name.to_s.camelize}Watcher"
      klass = LiveSync.const_get klass
      klass.new self
    end

    dsl :user, default: :root
    dsl :source do |source|
      raise "#{ctx}: source isn't a directory" unless File.directory? source
      fill_name source if !name
      source
    end

    attr_reader :dest
    dsl :target do |opts, block|
      @dest = opts[:rsync]
      Rsync.new self, source, @dest, &block
    end

    dsl :delay, default: 5, type: Integer

    dsl :modes, default: %i[create modify], type: Array

    dsl :delete, default: false, enum: [true,false] + %i[initial watched]

    dsl :excludes, default: []

    def start
      return log.warning('skipping disabled sync') && false unless enabled
      raise "#{ctx}: missing target" unless @target
      target.start
    end

    def guard
      fork do
        Process.setproctitle "livesync: sync #{ctx}"
        target.watch
        target.initial
        sleep 1.day while true
      end
    end

    protected

  end
end
