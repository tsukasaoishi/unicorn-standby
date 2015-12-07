require "unicorn/standby/version"
require 'unicorn/http_server'

module Unicorn
  module Standby
    def start
      @_wakeup ? super : self
    end

    def join
      @_wakeup ? super : standby
    end

    def standby
      proc_name 'master (standby)'
      ready_standby_trap

      standby_listeners = wait_request_listeners
      logger.info "standby ready"

      if @ready_pipe
        begin
          @ready_pipe.syswrite($$.to_s)
        rescue => e
          logger.warn("grandparent died too soon?: #{e.message} (#{e.class})")
        end
        @ready_pipe = @ready_pipe.close rescue nil
      end

      IO.select(standby_listeners)

      @_wakeup = true
      turn_on(standby_listeners)
    end

    private

    def ready_standby_trap
      [:QUIT, :TERM, :INT].each do |signal|
        Signal.trap(signal) { standby_shutdown }
      end
    end

    def wait_request_listeners
      listeners = ENV['UNICORN_FD'].to_s.split(/,/).map do |fd|
        io = Socket.for_fd(fd.to_i)
        prevent_autoclose(io)
        logger.info "inherited addr=#{sock_name(io)} fd=#{fd}"
        server_cast(io)
      end

      names = listeners.map { |io| sock_name(io) }

      new_listeners = config[:listeners].dup - names
      if new_listeners.empty? && listeners.empty?
        new_listeners << Unicorn::Const::DEFAULT_LISTEN
      end

      listeners + new_listeners.map {|addr| listen(addr) }
    end

    def turn_on(standby_listeners)
      set_unicorn_fds(standby_listeners)
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
