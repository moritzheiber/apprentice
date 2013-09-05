module Server
  class EventServer < EM::Connection
    require 'apprentice/checker'
    require 'mysql2/em'
    include Checker

    attr_accessor :client

    def initialize(options)
      @ip = options.ip
      @port = options.port
      @sql_port = options.sql_port
      @server = options.server
      @user = options.user
      @password = options.password
      @donor_allowed = options.donor_allowed
      @status = {}

      begin
        @client = Mysql2::Client.new(
            host: @server,
            port: @sql_port,
            username: @user,
            password: @password,
            as: :array,
            reconnect: true
        )
      rescue Exception => message
        puts message
        EM.stop_server
      end
    end

    def receive_data(data)
      response = run_checks
      response_text = format_text(response[:text])
      send_data generate_response(response[:code], response_text)
    end
  end
end
