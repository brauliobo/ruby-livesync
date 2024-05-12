module LiveSync
  class Sync

    include DSL

    attr_reader :name
    attr_reader :scheduler
    attr_reader :log
    attr_reader :watcher
    attr_reader :ssh
    attr_reader :rsync

    def initialize name = nil
      fill_name name
      source name if File.exist? name
      @to_sync = Set.new
    end

    def fill_name name
      return if @name
      self.ctx = @name = name
      @log = Log.new ctx
    end

    dsl :user, default: :root
    dsl :source do |source|
      raise "#{ctx}: source not found" unless File.exist? source
      fill_name source
      @pathname = Pathname.new source
    end

    dsl :target do |target|
      @userhost, @target_path = target.split(':')
      raise "#{ctx}: missing target path" unless @target_path
      @user, @host = if @userhost.index '@' then @userhost.split('@') else [@user, @userhost] end
    end

    dsl :delay, default: 1, type: Integer

    def run
      raise "#{ctx}: missing target" unless @target
      @ssh   = Ssh.connect @userhost
      @rsync = Rsync.new self
    end

    def guard
      fork do
        Process.setproctitle "livesync: sync #{ctx}"
        @watcher   = Watcher.new
        @scheduler = Rufus::Scheduler.new

        @watcher.dir_rwatch source, *%i[create modify], &method(:track)
        @rsync.initial
        @scheduler.every "#{delay}s", &method(:check)
        sleep 1.day while true
      end
    end

    def track event
      @to_sync << Pathname.new(event.absolute_name).relative_path_from(@pathname).to_s
    end

    def check
      return if @rsync.running?
      @watcher.process # calls #track
      @rsync.from_list @to_sync
      @to_sync.clear
    end

    protected

  end
end
