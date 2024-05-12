module LiveSync
  class Rsync

    attr_reader :sync
    attr_accessor :opts

    def initialize sync
      @sync = sync
      @opts = '-ax --partial'
    end

    def running?
      @wait_thr
    end

    def initial
      args  = []
      args << '--delete' if sync.delete.in? [true, :initial]
      run :initial, *args
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

    def run type, *args
      cmd = "rsync -e '#{rsh}' #{opts} #{sync.source} #{sync.target} #{args.join ' '}"
      sync.excludes.each{ |e| cmd << " --exclude='#{e}'" }

      sync.log.info "#{type}: starting with cmd: #{cmd}"
      stdin, stdout, stderr, @wait_thr = Open3.popen3 cmd
      yield stdin, stdout, stderr if block_given?
      Thread.new do
        Process.wait @wait_thr.pid rescue Errno::ECHILD; nil
        @wait_thr = nil
        sync.log.info "#{type}: finished"
      end
    end

    def rsh
      "ssh -o ControlPath=#{sync.ssh.cpath}"
    end

  end
end
