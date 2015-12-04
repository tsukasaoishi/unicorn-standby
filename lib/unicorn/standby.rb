require "unicorn/standby/version"

module Unicorn
  class Standby
    include Unicorn::SocketHelper

    SCRIPT_ARGV = ARGV.map { |arg| arg.dup }

    def initialize(app, options)
      @app = app
      @options = options
      @config = Unicorn::Configurator.new(options.merge(use_defaults: true))
      @logger = @config.set[:logger]
      @listeners = []
    end

    def standby
      ready_trap

      $0 = "unicorn master (standby mode)" + SCRIPT_ARGV.join(" ")
      wait_request

      turn_on
    end

    def turn_on
      set_unicorn_fds
      Unicorn::HttpServer.new(@app, @options).start.join
    end

    def ready_trap
      [:QUIT, :TERM, :INT].each do |signal|
        Signal.trap(signal) { shutdown }
      end
    end

    def shutdown
      puts "master complete (standby)"
      exit 0
    end

    def wait_request
      listeners = @config[:listeners].dup
      if listeners.empty?
        listeners << Unicorn::Const::DEFAULT_LISTEN
      end

      @listeners = listeners.map {|addr| listen(addr) }

      IO.select(@listeners)
    end

    def set_unicorn_fds
      listener_fds = {}
      @listeners.each do |sock|
        sock.close_on_exec = false if sock.respond_to?(:close_on_exec=)
        listener_fds[sock.fileno] = sock
      end
      ENV['UNICORN_FD'] = listener_fds.keys.join(',')
    end

    def listen(address)
      address = @config.expand_addr(address)

      delay = 0.5
      tries = 5

      begin
        io = bind_listen(address)
        unless Kgio::TCPServer === io || Kgio::UNIXServer === io
          prevent_autoclose(io)
          io = server_cast(io)
        end
        @logger.info "listening on addr=#{sock_name(io)} fd=#{io.fileno}"
        io
      rescue Errno::EADDRINUSE => err
        @logger.error "adding listener failed addr=#{address} (in use)"
        raise err if tries == 0
        tries -= 1
        @logger.error "retrying in #{delay} seconds " \
                     "(#{tries < 0 ? 'infinite' : tries} tries left)"
        sleep(delay)
        retry
      rescue => err
        @logger.fatal "error adding listener addr=#{address}"
        raise err
      end
    end
  end
end
