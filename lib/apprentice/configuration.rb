require 'optparse'
require 'ostruct'

module Configuration
  def get_config
    options = OpenStruct.new
    options.ip = '0.0.0.0'
    options.port = 3307
    options.sql_port = 3306
    options.accept_donor = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: apprentice [options]\n"
      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('-s SERVER', '--server SERVER',
        'Connect to SERVER') { |s| options.server = s }
      opts.on('-u USER', '--user USER',
        'USER to connect the server with') { |u| options.user = u }
      opts.on('-p PASSWORD', '--password PASSWORD',
        'PASSWORD to use') { |p| options.password = p }

      opts.on('-i', '--ip IP',
        'Local IP to bind to') { |i| options.ip = i }
      opts.on('--port PORT',
        'Local PORT to use') { |p| options.port = p }
      opts.on('--sql_port PORT',
        'Port of the MariaDB server to connect to') { |p| options.sql_port = p }
      opts.on('--[no-]accept-donor',
        'Accept cluster state "Donor/Desynced" as valid') { |ad| options.accept_donor = ad }

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
      ARGV << 's-h' if ARGV.size < 3
      opt_parser.parse!(ARGV)
      unless options.server && options.user && options.password
        $stderr.puts 'Error: you have to specify a user, a password and the server to connect to'
        $stderr.puts 'Try -h/--help for more options'
        exit
      end
      return options
    rescue OptionParser::ParseError
      $stderr.print "Error: #{$!}\n"
      exit
    end
  end
end