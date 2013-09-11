module Checker

  CODES = {200 => 'OK',503 => 'Service Unavailable'}

  case @type
    when 'galera'
      require 'apprentice/checks/galera'
      include Galera
    when 'mysql'
      require 'apprentice/checks/mysql'
      include Mysql_Checks
  end

  def format_text(texts)
    value = ''
    if !texts.empty?
      texts.each do |t|
        value << "#{t}\r\n"
      end
    end
    return value
  end

  def generate_response(code = 503, text)
    "HTTP/1.1 #{code} #{CODES[code]}\r\nContent-type: text/plain\r\nContent-length: #{text.length}\r\n\r\n#{text}"
  end
end