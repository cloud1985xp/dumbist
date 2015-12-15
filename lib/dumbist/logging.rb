require 'logger'

module Dumbist
  module Logging
    def self.initialize_logger(log_target = STDOUT)
      oldlogger = defined?(@logger) ? @logger : nil
      @logger = ::Logger.new(log_target)
      @logger.level = ::Logger::INFO
      # @logger.formatter = Pretty.new
      oldlogger.close if oldlogger
      @logger
    end

    def self.logger
      @logger || initialize_logger
    end

    def self.logger=(log)
      @logger = (log ? log : Logger.new('/dev/null'))
    end

    def logger
      Dumbist::Logging.logger
    end
  end
end