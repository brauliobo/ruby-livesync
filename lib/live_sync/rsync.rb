module LiveSync
  class Rsync < Target

    dsl :opts, default: '-ax --partial', type: String

    dsl :reverse_sync do |&block|
      opts << ' -u'
      @reverse_sync = ReverseRsync.new self, &block
    end

    attr_reader :ssh, :rprefix

    def initialize *args, &block
      super
      # add trailing slash in case the dir is the same
      sync.source File.join(sync.source, '') if File.basename(sync.source) == File.basename(@path)
      @rprefix = ' reverse:' if reverse
    end

    def start
      @ssh  = Ssh.connect userhost
      sleep 1 and log.warning 'waiting for ssh' while !@ssh.available?
      true
    end

    def running?
      @wait_thr or reverse_sync&.running?
    end

    def initial
      args  = []
      args << '--delete' if sync.delete.in? [true, :initial]
      run :initial, *args, loglevel: :info

      reverse_sync.initial if reverse_sync
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
      cmd = "rsync -e '#{rsh}' #{opts} #{sync.source} #{dest} #{args.join ' '}"
      sync.excludes.each{ |e| cmd << " --exclude='#{e}'" }

      log.send loglevel, "#{type}:#{rprefix} starting with cmd: #{cmd}"
      stdin, stdout, stderr, @wait_thr = Open3.popen3 cmd
      yield stdin, stdout, stderr if block_given?
      Thread.new do
        Process.wait @wait_thr.pid rescue Errno::ECHILD; nil
        @wait_thr = nil
        log.send loglevel, "#{type}:#{rprefix} finished"
      end
    end

    def rsh
      "ssh -o ControlPath=#{ssh.cpath}"
    end

  end
end
