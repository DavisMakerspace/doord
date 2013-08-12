require 'logger'
require 'socket'
require 'json'

class JSONServerException < RuntimeError; end

class JSONServer
  def initialize(server, log = Logger.new(STDERR))
    @server = server
    @log = log
  end
  def run()
    loop do
      begin
        socket = @server.accept
      rescue Exception => error
        @log.error { error.inspect }
      else
        yield JSONServerClient.new(self, socket)
      end
    end
  end
  attr_reader :log
end

class JSONServerClient
  attr_reader :socket
  def initialize(server, socket)
    @server = server
    @socket = socket
    @log = @server.log
    @log.info { "New connection #{@socket}" }
  end
  def receive()
    @socket.each do |line|
      line.strip!
      msg = {}
      if line.start_with? '{'
        begin
          msg = JSON::parse(line, {:symbolize_names => true})
        rescue Exception => error
          @log.error { error.inspect }
          send_error(error)
        end
      elsif line.size > 0
        send({error: "Unrecognized message"})
      end
      if msg != {}
        @log.info { "Client command: #{msg}" }
        begin
          yield msg
        rescue Exception => error
          @log.error { error }
          send_error(error)
        end
      end
    end
  end
  def send(msg)
    @socket.write(msg.to_json + "\r\n")
    @log.info { "Send to client: #{msg}" }
  end
  def send_error(error)
    send({error: {type: error.class.name, message: error.message}})
  end
end
