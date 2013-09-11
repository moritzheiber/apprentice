require 'optparse'
require 'ostruct'

module Configuration
  def get_config
    options = OpenStruct.new
    options.ip = '0.0.0.0'
    options.port = 3307
    options.sql_port = 3306
    options.accept_donor = false
    options.threshold = 120

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: apprentice [options]\n"
      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('-s SERVER', '--server SERVER',
        'SERVER to connect to') { |s| options.server = s }
      opts.on('-u USER', '--user USER',
        'USER to connect to the server with') { |u| options.user = u }
      opts.on('-p PASSWORD', '--password PASSWORD',
        'PASSWORD to use') { |p| options.password = p }
      opts.on('-t TYPE', '--type TYPE',
        'TYPE of server. Must either by "galera" or "mysql".') { |t| options.type = t }

      opts.on('-i', '--ip IP',
        'Local IP to bind to',
        "(default: #{options.ip})") { |i| options.ip = i }
      opts.on('--port PORT',
        'Local PORT to use',
        "(default: #{options.port})") { |p| options.port = p }
      opts.on('--sql_port PORT',
        'Port of MariaDB/MySQL server to connect to',
        "(default: #{options.sql_port})") { |p| options.sql_port = p }
      opts.on('--[no-]accept-donor',
        'Accept galera cluster state "Donor/Desynced" as valid',
        "(default: #{options.accept_donor})") { |ad| options.accept_donor = ad }
      opts.on('--threshold SECONDS',
        'MariaDB/MySQL slave lag threshold',
        "(default: #{options.threshold})") { |tr| options.threshold = tr }

      opts.separator ''
      opts.separator 'Common options:'

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
      opts.on_tail('-v', '--version', 'Show version') do
        puts "Apprentice #{Apprentice::VERSION}"
        exit
      end
    end

    begin
      opt_parser.parse!(ARGV)
      unless options.server &&
          options.user &&
          options.password &&
          check_type(options.type)
        $stderr.puts 'Error: you have to specify a user, a password, a server to connect to'
        $stderr.puts 'and a valid type. It can either by "galera" or "mysql".'
        $stderr.puts 'Try -h/--help for more options'
        exit
      end
      return options
    rescue OptionParser::ParseError
      $stderr.print "Error: #{$!}\n"
      exit
    end
  end

  def check_type(type)
    %w{galera mysql}.each do |t|
      return true if t == type
    end
    false
  end
end