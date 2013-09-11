module Mysql_Checks
  def get_mysql_status
    begin
      client = Mysql2::Client.new(
          host: @server,
          port: @sql_port,
          username: @user,
          password: @password
      )
      result = client.query 'SHOW SLAVE STATUS;'
      if result.count > 0
        result.each do |key,state|
          @status[key] = state
        end
      end
      client.close
    rescue Exception => message
      puts message
    end
  end

  def check_io
    return true if @status['Slave_IO_Running'] == 'Yes'
    false
  end
  def check_seconds_behind
    return true if Integer(@status['Seconds_Behind_Master']) < @threshold
  end

  def run_checks
    get_mysql_status
    unless @status.empty?
      response = {code: 200, text: []}
      if !check_io
        response[:text] << 'Slave IO is not running.'
      end
      if !check_seconds_behind
        response[:text] << "Slave is running #{@status['Seconds_Behind_Master']} seconds behind"
      end
      response[:code] = 503 unless response[:text].empty?
      return response
    else
      return {code: 503, text: ['Unable to determine slave status']}
    end
  end
end