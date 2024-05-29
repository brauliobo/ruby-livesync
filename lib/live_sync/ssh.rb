require 'tempfile'
require 'open3'

module LiveSync
  class Ssh

    class_attribute :cache
    self.cache = {}

    def self.connect userhost
      cache[userhost] ||= new userhost
    end

    attr_reader :userhost, :cpath

    def initialize userhost
      @userhost = userhost
      @tmpfile  = Tempfile.new "livesync-controlpath"
      @cpath    = @tmpfile.path
      File.unlink @cpath
      connect
    end

    def connect
      Thread.new do
        loop do
          cmd = "ssh -nN -o ControlMaster=yes -o ControlPath=#{cpath} #{userhost}"
          stdin, stdout, stderr, @wait_thr = Open3.popen3 cmd
          Process.wait @wait_thr.pid
          Log.error "ssh/#{userhost}: #{stderr.read}"
          stdin.close; stdout.close; stderr.close
        end
      end
    end

    def available?
      return false unless File.exist? cpath
      system "ssh -O check -o ControlPath=#{cpath} dummy > /dev/null 2>&1"
    end

  end
end
