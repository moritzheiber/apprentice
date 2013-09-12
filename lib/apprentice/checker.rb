# Contains all the relevant methods for checking on a server's state
#
# Conditionally includes either MariaDB/MySQL or Galera related checking code
module Checker

  # HTTP response codes and their respective return value
  #
  # We're constructing our dumb HTTP response handler using these
  CODES = {200 => 'OK',503 => 'Service Unavailable'}

  case @type
    when 'galera'
      require 'apprentice/checks/galera'
      include Galera
    when 'mysql'
      require 'apprentice/checks/mysql'
      include Mysql_Checks
  end

  # Format our HTTP/1.1 response properly without using arbitrary line breaks.
  #
  # ==== Attributes
  #
  # * +texts+ - A hash containing all text responses returned from run_checks.
  #
  # ==== Return values
  #
  # * +value+ - The comprehensive text returned with a HTTP response.
  #
  # ==== Examples
  #
  #    t = ['Something', 'Something else']
  #    response = format_text(t)
  #    response.inspect # => 'Something\r\nSomething else\r\n'
  def format_text(texts)
    value = ''
    if !texts.empty?
      texts.each do |t|
        value << "#{t}\r\n"
      end
    end
    return value
  end

  # Generates the actual output returned by the Server::EventServer class.
  #
  # It's valid HTTP/1.1 and should be understood by almost any browser. Certainly by HAProxy's httpchk.
  #
  # ==== Attributes
  #
  # * +code+ - The HTTP code for the returned response
  # * +text+ - Formatted text to be returned with the response
  #
  # ==== Return values
  #
  # * String - A HTTP response string
  #
  # ==== Examples
  #
  #    code = 503
  #    text = 'Something is wrong'
  #
  #    response = generate_response(code, text)
  #    response.inspect # => 'HTTP/1.1 503 Service Unavailable\r\nContent-type: text/plain\r\nContent-length: 18\r\n\r\nSomething is wrong\r\n'
  def generate_response(code = 503, text)
    "HTTP/1.1 #{code} #{CODES[code]}\r\nContent-type: text/plain\r\nContent-length: #{text.length}\r\n\r\n#{text}"
  end
end