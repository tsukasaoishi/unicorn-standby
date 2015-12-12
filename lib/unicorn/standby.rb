require "unicorn/standby/version"
require 'unicorn'

module Unicorn
  module Standby
    EXIT_SIGS = [:QUIT, :TERM, :INT]
    private_constant :EXIT_SIGS

    def start
      @_wakeup ? super : self
    end

    def join
      @_wakeup ? super : standby
    end

    private

    def inherit_listeners!
      super unless @_wakeup
    end

    def bind_new_listeners!
      super unless @_wakeup
    end

    def standby
      self.pid = config[:pid]

      proc_name 'master (standby)'

      kill_old_master
      ready_standby_trap

      inherit_listeners!
      bind_new_listeners!

      logger.info "standby ready"
      notice_to_grandparent

      IO.select(self.class.const_get(:LISTENERS))

      turn_on
    end

    def kill_old_master
      old_pid = "#{config[:pid]}.oldbin"
      if File.exists?(old_pid) && pid != old_pid
        sig = :QUIT
        logger.info "Sending #{sig} signal to old unicorn master..."
        Process.kill(sig, File.read(old_pid).to_i)
      end
    rescue Errno::ENOENT, Errno::ESRCH
    end

    def ready_standby_trap
      (unicorn_queue_sigs - EXIT_SIGS).each do |signal|
        Signal.trap(signal) {}
      end

      EXIT_SIGS.each do |signal|
        Signal.trap(signal) { standby_shutdown }
      end
    end

    def notice_to_grandparent
      return unless @ready_pipe

      begin
        @ready_pipe.syswrite($$.to_s)
      rescue => e
        logger.warn("grandparent died too soon?: #{e.message} (#{e.class})")
      end
      @ready_pipe = @ready_pipe.close rescue nil
    end

    def turn_on
      logger.info "standby master wake up..."
      @_wakeup = true
      start.join
    end

    def standby_shutdown
      unlink_pid_safe(pid) if pid
      exit 0
    end

    def unicorn_queue_sigs
      if self.class.const_defined?(:QUEUE_SIGS)
        self.class.const_get(:QUEUE_SIGS)
      else
        @queue_sigs || []
      end
    end
  end
end

unless Unicorn::HttpServer.ancestors.include?(Unicorn::Standby)
  Unicorn::HttpServer.__send__(:prepend , Unicorn::Standby)
end
