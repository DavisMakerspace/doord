require 'socket'
require 'json'

class JSONServerException < RuntimeError; end

class JSONServer
  def initialize(server)
    @server = server
  end
  def run()
    loop do
      begin
        socket = @server.accept
      rescue Exception => error
        $LOG.error { error.inspect }
      else
        yield JSONServerClient.new(self, socket)
      end
    end
  end
end

class JSONServerClient
  attr_reader :socket
  def initialize(server, socket)
    @server = server
    @socket = socket
    $LOG.info { "New connection #{@socket}" }
  end
  def receive()
    @socket.each do |line|
      line.strip!
      msg = {}
      if line.start_with? '{'
        begin
          msg = JSON::parse(line, {:symbolize_names => true})
        rescue Exception => error
          $LOG.error { error.inspect }
          send_error(error)
        end
      elsif line.size > 0
        send({error: "Unrecognized message"})
      end
      if msg != {}
        $LOG.info { "Client command: #{msg}" }
        begin
          yield msg
        rescue Exception => error
          $LOG.error { error }
          send_error(error)
        end
      end
    end
  end
  def send(msg)
    @socket.write(msg.to_json + "\r\n")
    $LOG.info { "Send to client: #{msg}" }
  end
  def send_error(error)
    send({error: {type: error.class.name, message: error.message}})
  end
end
