require 'logger'
require 'socket'
require 'json'

class JSONServer
  def initialize(server, log = Logger.new(STDERR))
    @server = server
    @log = log
  end
  def accept()
    return JSONClient.new(self, @server.accept)
  end
  attr_reader :log
end

class JSONClient
  def initialize(server, socket)
    @server = server
    @socket = socket
    @log = @server.log
    @log.info { "New connection #{@socket}" }
  end
  def receive()
    @socket.each do |line|
      line.strip!
      @log.info { "Received client message: #{line.dump}" }
      begin
        msg = JSON::parse(line, {:symbolize_names => true})
      rescue JSON::ParserError => error
        @log.error { "Client message resulted in JSON parse error #{error}" }
        send({error: error})
        msg = {}
      else
        @log.info { "Client command: #{msg}" }
        yield msg
      end
    end
  end
  def send(msg)
    @socket.write(msg.to_json + "\r\n")
    @log.info { "Send to client: #{msg}" }
  end
end
