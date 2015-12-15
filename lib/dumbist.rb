require "dumbist/version"
require "dumbist/logging"

module Dumbist

  DEFAULT_OPTIONS = { require: 'dumbist.rb', timeout: 10 }

  module_function

  def options
    @options ||= DEFAULT_OPTIONS.dup
  end

  def logger
    Dumbist::Logging.logger
  end

  def logger=(log)
    Dumbist::Logging.logger = log
  end
end
