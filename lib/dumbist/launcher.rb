module Dumbist
  class Launcher
    def initialize(options)
      @options = options
    end

    def run
      f = File.expand_path(@options[:require])
      require f

      # start_heartbeat
    end

    def stop
      # Dumbist.logger.info "Stopping your program"
      begin
        # invoke the callback of custom process
      rescue Exception => e

      end
      @done = true
      # stop_heartbeat
    end

    private

    # def stop_heartbeat
    # end
  end
end