module Galera
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
        result.each do |r|
          @status.merge!(Hash[*r])
        end
      end
      client.close
    rescue Exception => message
      puts message
    end
  end

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

  def check_cluster_size
    return true if Integer(@status['wsrep_cluster_size']) > 1
    false
  end

  def check_ready_state
    return true if @status['wsrep_ready'] == 'ON'
    false
  end

  def check_local_state
    s = Integer(@status['wsrep_local_state'])
    return true if s == 4 || (s == 2 && @donor_allowed)
    false
  end

end