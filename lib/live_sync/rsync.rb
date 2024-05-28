module LiveSync
  class Rsync < Target

    dsl :opts, default: '-ax --partial', type: String

    dsl :reverse_sync do |v, block|
      ReverseRsync.new self, &block
    end

    attr_reader :ssh, :rprefix

    def initialize *args, **params, &block
      super *args, **params, &block
      # add trailing slash in case the dir name is the same
      @source  = File.join source, '' if File.basename(source) == File.basename(dest)
      @rprefix = 'reverse: ' if reverse
    end

    def start
      @ssh  = Ssh.connect userhost
      sleep 1 and log.warning 'waiting for ssh' while !@ssh.available?
      true
    end

    def running?
      @wait_thr
    end

    def initial
      args  = []
      args << '--delete' if sync.delete.in? [true, :initial]
      run :initial, *args, loglevel: :info

      @reverse_sync&.initial
    end

    def partial paths
      args  = ['--files-from=-']
      args << '--delete-missing-args' if sync.delete.in? [true, :watched]
      run :partial, *args do |stdin, stdout, stderr|
        stdin.write paths.join "\n"
        stdin.close
      end
    end

    protected

    def run type, *args, loglevel: :debug
      cmd = "rsync -e '#{rsh}' #{opts} #{source} #{dest} #{args.join ' '}"
      sync.excludes.each{ |e| cmd << " --exclude='#{e}'" }

      log.send loglevel, "#{rprefix}#{type}: starting with cmd: #{cmd}"
      return binding.pry if Daemon.dry
      stdin, stdout, stderr, @wait_thr = Open3.popen3 cmd
      yield stdin, stdout, stderr if block_given?

      Thread.new do
        Process.wait @wait_thr.pid rescue Errno::ECHILD; nil
        @wait_thr = nil
        log.send loglevel, "#{rprefix}#{type}: finished"
      end
    end

    def rsh
      # -t -t ensure the running process is killed with the client
      "ssh -o ControlPath=#{ssh.cpath}"
    end

  end
end
