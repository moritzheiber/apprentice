require 'eventmachine'
require 'apprentice/configuration'
require 'apprentice/version'
require 'apprentice/server'

module Apprentice
  class Sentinel
    include Configuration
    include Server

    def initialize
      @options = get_config
    end

    def run
      EM.run do
        Signal.trap('INT') { EventMachine.stop }
        Signal.trap('TERM') { EventMachine.stop }
        EventMachine.start_server(
            @options.ip,
            @options.port,
            Server::EventServer,
            @options
        )
      end
    end
  end
end