require 'eventmachine'
require 'apprentice/configuration'
require 'apprentice/version'
require 'apprentice/server'

# The main Apprentice module including all other modules and classes
module Apprentice

  # This defines the sentinel, i.e. tiny server, Apprentice uses to communicate with e.g. HAProxy's httpchk method.
  class Sentinel
    include Configuration #:nodoc:
    include Server        #:nodoc:

    # This depends on the Configuration module since it uses the Configuration#get_config method.
    #
    # ==== Return value
    #
    # * <tt>@options</tt> - set the global variable <tt>@options</tt> which is used inside #run the start the EventMachine server
    def initialize
      @options = get_config
    end

    # Starts the EventMachine server
    #
    # === Special conditions
    #
    # We are trapping the signals <tt>INT</tt> and <tt>TERM</tt> here in order to shut down the EventMachine gracefully.
    #
    # ==== Attributes
    #
    # * <tt>@options.ip</tt> - The server binds to this specific ip
    # * <tt>@options.port</tt> - The server uses this specific port to expose its limited HTTP interface to the world
    # * <tt>@options</tt> - Gets passed to the server as a whole to be used with Server::EventServer#initialize
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