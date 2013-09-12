# Main server module consisting of all server related methods and classes
module Server

  # The actual EM::Connection instance referenced by the EventServer class.
  # Notice that we use Mysql2::Client::EM instead of the regular Mysql2::Client class.
  class EventServer < EM::Connection
    require 'apprentice/checker'
    require 'mysql2/em'
    include Checker

    def initialize(options) #:nodoc:
      @ip = options.ip
      @port = options.port
      @sql_port = options.sql_port
      @server = options.server
      @user = options.user
      @password = options.password
      @donor_allowed = options.donor_allowed
      @type = options.type
      @threshold = options.threshold
      @status = {}
    end

    # Take the raw data received on @port and run initiate the checks against the server located at @server
    #
    # ==== Special conditions
    #
    # We are sending something to our client with #send_data inside the function, depending on what #run_checks returned to us during the function call.
    #
    # ==== Attributes
    #
    # * +data+ - We receive the actual HTTP request but since we're not a full blown HTTP server we don't actually use it to any extent
    def receive_data(data)
      response = run_checks
      response_text = format_text(response[:text])
      send_data generate_response(response[:code], response_text)
    end
  end
end
