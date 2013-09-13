# Contains MariaDB/MySQL specific methods for checking on slave health
module Mysql_Checks

  # Gets the actual status from the MariaDB/MySQL slave using the Mysql2 gem.
  # Notice that we're using the EventMachine-enabled Mysql2::Client.
  #
  # Right now it only returns the relevant error output and continues working afterwards.
  #
  # Nothing is mentioned about explicitly closing a client connection in the Mysql2 docs,
  # however, we need to be careful with the amount of connections we're using since we might
  # find ourselves in an environment where the number of connections is constraint for a very few.
  #
  # ==== Return values
  #
  # * @status - Contains a hash of all the relevant replication related variables to be examined by #run_checks
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
        result.each do |key, state|
          @status[key] = state
        end
      end
      client.close
    rescue Exception => message
      puts message
    end
  end

  # Get the value of <tt>'Slave_IO_Running'</tt>, which, obviously, should be <tt>Yes</tt> since otherwise
  # it would mean the slave is not replicated properly and/or has stopped because of an error.
  #
  # ==== Attributes
  #
  # * <tt>@status</tt> - Uses the <tt>'Slave_IO_Running'</tt> key inside the hash.
  #
  # ==== Return values
  #
  # +true+ or +false+ - depending on whether or not the slave's replication thread is running.
  #
  # ==== Examples
  #
  #    @status = Hash.new
  #    @status['Slave_IO_Running'] = 'Yes'
  #
  #    r = check_slave_io
  #    r.inspect # => true
  #
  #    @status['Slave_IO_Running'] = 'No'
  #
  #    r = check_slave_io
  #    r.inspect # => false
  def check_slave_io
    return true if @status['Slave_IO_Running'] == 'Yes'
    false
  end

  # Get the value of <tt>'Seconds_Behind_Master'</tt>, which indicates the amount of time in seconds
  # the slave is behind the master's instruction set received via the replication thread. This should
  # always be as close to zero as possible (or even zero). If this value is beyond <tt>@threshold</tt>
  # constantly you will need to think about changing your setup to accommodate the traffic coming in
  # from the master.
  #
  # ==== Attributes
  #
  # * <tt>@status</tt> - Uses the <tt>'Seconds_Behind_Master'</tt> key inside the hash
  # * <tt>@threshold</tt> - The globally defined threshold after which the slave is considered to be too far behind to still be an active member. The default is 120 seconds.
  #
  # ==== Return values
  #
  # +true+ or +false+ - depending on whether or not the slave's replication thread is behind <tt>@threshold</tt>
  #
  # ==== Examples
  #
  #    @status = Hash.new
  #    @status['Slave_IO_Running'] = 'Yes'
  #
  #    r = check_slave_io
  #    r.inspect # => true
  #
  #    @status['Slave_IO_Running'] = 'No'
  #
  #    r = check_slave_io
  #    r.inspect # => false
  def check_seconds_behind
    return true if Integer(@status['Seconds_Behind_Master']) < @threshold
  end

  # Returns the relevant status HTTP code accompanied by a useful user feedback text
  #
  # ==== Attributes
  #
  # * @status - Should contain a hash with the relevant information to determine the
  #   the cluster member status. Also see #get_mysql_status.
  #
  # ==== Return values
  #
  # * +response+ - A hash containing a HTTP <tt>:code</tt> and a <tt>:text</tt> to return to the user
  #
  # ==== Example
  #
  #    @status = {'Seconds_Behind_Master' => 140 }
  #    response = self.run_checks
  #    response.inspect # => {:code => 503, :text => 'Some text'}
  def run_checks
    get_mysql_status
    unless @status.empty?
      response = {code: 200, text: []}
      if !check_slave_io
        response[:text] << 'Slave IO is not running.'
      end
      if !check_seconds_behind
        response[:text] << "Slave is #{@status['Seconds_Behind_Master']} seconds behind. Threshold is #{@threshold}"
      end
      response[:code] = 503 unless response[:text].empty?
      return response
    else
      return {code: 503, text: ['Unable to determine slave status']}
    end
  end
end