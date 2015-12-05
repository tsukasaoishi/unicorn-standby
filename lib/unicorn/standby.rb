require "unicorn/standby/version"
require 'unicorn/http_server'

module Unicorn
  module Standby
    def start
      super if @_not_standby
    end

    def join
      if @_not_standby
        super
      else
         standby
      end
    end

    private

    def standby
      proc_name 'master (standby)'
      ready_standby_trap

      standby_listeners = wait_request_listeners
      logger.info "standby ready"

      IO.select(standby_listeners)

      turn_on(standby_listeners)
    end

    def ready_standby_trap
      [:QUIT, :TERM, :INT].each do |signal|
        Signal.trap(signal) { standby_shutdown }
      end
    end

    def wait_request_listeners
      listeners = config[:listeners].dup
      if listeners.empty?
        listeners << Unicorn::Const::DEFAULT_LISTEN
      end

      listeners.map {|addr| listen(addr) }
    end

    def turn_on(standby_listeners)
      set_unicorn_fds(standby_listeners)
      @_not_standby = true
      start.join
    end

    def standby_shutdown
      logger.info "master complete (standby)"
      exit 0
    end

    def set_unicorn_fds(standby_listeners)
      listener_fds = {}
      standby_listeners.each do |sock|
        sock.close_on_exec = false if sock.respond_to?(:close_on_exec=)
        listener_fds[sock.fileno] = sock
      end
      ENV['UNICORN_FD'] = listener_fds.keys.join(',')
    end
  end
end

unless Unicorn::HttpServer.include?(Unicorn::Standby)
  Unicorn::HttpServer.__send__(:prepend , Unicorn::Standby)
end
