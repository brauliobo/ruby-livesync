module LiveSync
  class Log

    class_attribute :ctx
    class_attribute :global
    self.global = self.new
    class << self
      delegate_missing_to :global
    end

    class_attribute :level
    self.level = if !!ENV['DEBUG'] then :debug else :warning end

    def self.debug?; level == :debug; end

    def initialize ctx=nil
      self.ctx = ctx
    end

    def debug msg
      return unless Log.debug?
      puts "DEBUG: #{parse msg}"
    end

    def info msg
      puts "INFO: #{parse msg}"
    end

    def warning msg
      STDERR.puts "WARNING: #{parse msg}"
    end

    def error msg
      STDERR.puts "ERROR: #{parse msg}"
    end

    def fatal msg
      STDERR.puts "FATAL: #{parse msg}"
    end

    def parse msg
      msg = "#{ctx}: #{msg}" if ctx
      msg
    end

  end
end
