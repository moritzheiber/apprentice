# Contains Galera specific methods for checking cluster member consistency
module Galera

  # Galera knows {a couple of different states}[http://www.percona.com/doc/percona-xtradb-cluster/wsrep-status-index.html#wsrep_local_state].
  # This constant describes their respective meaning for user feedback and, possibly, logging purposes.
  STATES = {1 => 'Joining',2 => 'Donor/Desynced',3 => 'Joined',4 => 'Synced'}

  # Gets the actual status from the Galera cluster member using the Mysql2 gem.
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
  # * @status - Contains a hash of all the relevant wsrep_* variables to be examined by #run_checks
  def get_galera_status
    begin
      client = Mysql2::Client.new(
          host: @server,
          port: @sql_port,
          username: @user,
          password: @password,
          as: :array
      )
      result = client.query "SHOW STATUS LIKE 'wsrep_%';"
      if result.count > 0

        # We need to do some conversion here in order to get a usable hash
        result.each do |r|
          @status.merge!(Hash[*r])
        end
      end
      client.close
    rescue Exception => message
      # FIXME Properly handle exception
      puts message
    end
  end

  # Returns the relevant status HTTP code accompanied by a useful user feedback text
  #
  # ==== Attributes
  #
  # * @status - Should contain a hash with the relevant information to determine the
  #   the cluster member status. Also see #get_galera_status.
  #
  # ==== Return values
  #
  # * +response+ - A hash containing a HTTP <tt>:code</tt> and a <tt>:text</tt> to return to the user
  #
  # ==== Example
  #
  #    @status = {'wsrep_cluster_size' => 4 }
  #    response = self.run_checks # => {:code => 503, :text => 'Some text'}
  def run_checks
    get_galera_status
    unless @status.empty?
      response = {code: 200, text: []}
      if !check_cluster_size
        response[:text] << "Cluster size is #{@status['wsrep_cluster_size']}. Split-brain situation is likely."
      end
      if !check_ready_state
        response[:text] << 'Cluster replication is not running.'
      end
      if !check_local_state
        response[:text] << "Local state is '#{STATES[@status['wsrep_local_state']]}'."
      end
      response[:code] = 503 unless response[:text].empty?
      return response
    else
      return {code: 503, text: ['Unable to determine cluster status']}
    end
  end

  # Checks whether the cluster size as reported by the member is above 1.
  # Any value below 2 is considered bad, as a cluster, by definition, should consist of at least
  # 2 members connected to each other.
  #
  # A cluster size of 1 might also indicate a split-brain situation.
  #
  # ==== Return values
  #
  # * +true+ or +false+ - depending on the value of <tt>@status['wsrep_cluster_size']</tt>
  #
  # ==== Examples
  #
  #    @status = Hash.new
  #
  #    @status['wsrep_cluster_size'] = 3
  #    r = check_cluster_size
  #    r.inspect # => true
  #
  #    @status['wsrep_cluster_size'] = 1
  #    r = check_cluster_size
  #    r.inspect # => false
  def check_cluster_size
    return true if Integer(@status['wsrep_cluster_size']) > 1
    false
  end

  # Checks whether the cluster replication is running and active.
  # If this returns false the <tt>'wsrep_ready'</tt> status variable is set to <tt>'OFF'</tt> and thus the server is not an active
  # member of a running cluster.
  #
  # ==== Return values
  #
  # * +true+ or +false+ - depending on the value of <tt>@status['wsrep_ready']</tt>
  #
  # ==== Examples
  #
  #    @status = Hash.new
  #
  #    @status['wsrep_ready'] = 'ON'
  #    r = check_ready_state
  #    r.inspect # => true
  #
  #    @status['wsrep_ready'] = 'OFF'
  #    r = check_ready_state
  #    r.inspect # => false
  def check_ready_state
    return true if @status['wsrep_ready'] == 'ON'
    false
  end

  # Checks how the cluster member sees itself in terms of status
  #
  # Valid states, read from the <tt>'wsrep_local_state'</tt> variable and depending on the configuration, are <tt>4</tt>, meaning <tt>Synced</tt>, or <tt>2</tt>,
  # meaning <tt>Donor/Desynced</tt>, if the option <tt>--accept-donor</tt> was passed at runtime.
  #
  # ==== Return values
  #
  # * +true+ or +false+ - depending on the value of <tt>@status['wsrep_local_state']</tt>
  #
  # ==== Examples
  #
  #    @status = Hash.new
  #    @donor_allowed = false
  #
  #    @status['wsrep_local_state'] = 4
  #    r = check_local_state
  #    r.inspect # => true
  #
  #    @status['wsrep_local_state'] = 2
  #    r = check_local_state
  #    r.inspect # => false
  #
  #    @donor_allowed = true
  #    @status['wsrep_local_state'] = 2
  #    r = check_local_state
  #    r.inspect # => true
  def check_local_state
    s = Integer(@status['wsrep_local_state'])
    return true if s == 4 || (s == 2 && @donor_allowed)
    false
  end

end