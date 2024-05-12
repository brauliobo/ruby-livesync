module LiveSync
  class Log

    class_attribute :global
    self.global = self.new
    class << self
      delegate_missing_to :global
    end

    class_attribute :ctx

    LEVELS = {
       debug:   0,
       verbose: 1,
       info:    2,
       warning: 3,
       error:   4,
       fatal:   5,
     }
    class_attribute :level
    self.level = if !!ENV['DEBUG'] then :debug else ENV['LEVEL']&.to_sym || :info end
    def self.debug?; level == :debug; end

    def initialize ctx=nil
      self.ctx = ctx
    end

    def log? level
      LEVELS[level] >= LEVELS[self.level]
    end

    def debug msg
      puts "DEBUG: #{parse msg}" if log? :debug
    end
    def info msg
      puts "INFO: #{parse msg}" if log? :info
    end

    def warning msg
      STDERR.puts "WARNING: #{parse msg}" if log? :warning
    end
    def error msg
      STDERR.puts "ERROR: #{parse msg}" if log? :error
    end
    def fatal msg
      STDERR.puts "FATAL: #{parse msg}" if log? :fatal
    end

    protected

    def parse msg
      msg = "#{ctx}: #{msg}" if ctx
      msg
    end

  end
end
