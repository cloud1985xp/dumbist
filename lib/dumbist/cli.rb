require 'singleton'
require 'optparse'
require 'dumbist'

module Dumbist
  class CLI
    include Singleton

    def parse(args=ARGV)
      setup_options(args)
      initialize_logger
      daemonize
      write_pid
    end

    def run
      boot_system
      self_read, self_write = IO.pipe

      %w(INT TERM USR1 USR2 TTIN).each do |sig|
        begin
          trap sig do
            self_write.puts(sig)
          end
        rescue ArgumentError
          puts "Signal #{sig} not supported"
        end
      end

      require 'dumbist/launcher'

      @launcher = Dumbist::Launcher.new(options)

      begin
        @launcher.run

        while readable_io = IO.select([self_read])
          signal = readable_io.first[0].gets.strip
          handle_signal(signal)
        end
      rescue Interrupt
        @launcher.stop
        exit(0)
      end
    end

    def set_environment(cli_env)
      @set_environment = cli_env || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    def setup_options(args)
      opts = parse_options(args)
      set_environment opts[:environment]
      options.merge!(opts)
    end

    def parse_options(argv)
      opts = {}
      @parser = ::OptionParser.new do |o|
        o.on '-d', '--daemon', 'Daemonize process' do |arg|
          opts[:daemon] = arg
        end

        o.on '-e', '--environment ENV', 'Application environment' do |arg|
          opts[:environment] = arg
        end

        o.on '-L', '--logfile PATH', 'path to writable logfile' do |arg|
          opts[:logfile] = arg
        end

        o.on '-P', '--pidfile PATH', 'path to writable pidfile' do |arg|
          opts[:pidfile] = arg
        end

        o.on '-r', '--require PATH', 'Location of file to require for launching the process' do |arg|
          opts[:require] = arg
        end

        o.on '-t', '--timeout NUM', "Shutdown timeout" do |arg|
          opts[:timeout] = Integer(arg)
        end

        o.on '-v', '--version', 'Print version and exit' do |arg|
          puts "Dumbist #{Dumbist::VERSION}"
          die(0)
        end
      end

      @parser.on_tail '-h', '--help', 'Show help' do
        logger.info @parser
        die(1)
      end

      @parser.parse!(argv)
      opts
    end

    def options
      Dumbist.options
    end

    private

    def program_name
      "Dumbist"
    end

    def write_pid
      if path = options[:pidfile]
        pidfile = File.expand_path(path)
        File.open(pidfile, 'w') do |f|
          f.puts ::Process.pid
        end
      end
    end

    def daemonize
      return unless options[:daemon]
      raise ArgumentError, "You really should set a logfile if you're going to daemonize" unless options[:logfile]

      files_to_reopen = []
      ObjectSpace.each_object(File) do |file|
        files_to_reopen << file unless file.closed?
      end

      ::Process.daemon(true, true)

      files_to_reopen.each do |file|
        begin
          file.reopen file.path, 'a+'
          file.sync = true
        rescue ::Exception
        end
      end

      [$stdout, $stderr].each do |io|
        File.open(options[:logfile], 'ab') do |f|
          io.reopen(f)
        end
        io.sync = true
      end

      $stdin.reopen('/dev/null')

      initialize_logger
    end

    def handle_signal(sig)
      case sig
      when 'INT'
        logger.info "Interrupt #{program_name}"
        raise Interrupt
      when 'TERM'
        logger.info "Terminate #{program_name}"
        raise Interrupt
      when 'USR1'
        # TODO
        # fire_event(:quiet)

      when 'USR2'
        # TODO: reopen log file

      when 'TTIN'
        Thread.list.each do |thread|
          Dumbist.logger.info "Thread TID-#{thread.object_id.to_s(36)} #{thread['label']}"
          if thread.backtrace
            Dumbist.logger.info thread.backtrace.join("\n")
          else
            Dubmist.logger.info "<no backtrace available>"
          end
        end
      end
    end

    def initialize_logger
      Dumbist::Logging.initialize_logger(options[:logfile]) if options[:logfile]
    end

    def boot_system
      # TODO
      # For supporting application framework? e.g. Rails
    end

    def logger; Dumbist.logger; end
  end
end