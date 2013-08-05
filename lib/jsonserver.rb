require 'logger'
require 'socket'
require 'json'
require 'yaml/store'
require 'securerandom'

class JSONServer
  def initialize(server, registry, log = Logger.new(STDERR))
    @server = server
    @registry = registry
    @log = log
  end
  def run()
    while socket = @server.accept
      yield JSONClient.new(self, socket)
    end
  end
  attr_reader :registry, :log
end

class JSONClient
  def initialize(server, socket)
    @server = server
    @socket = socket
    @log = @server.log
    @reg_data = nil
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
      end
      @log.info { "Client command: #{msg}" }
      apikey = msg.delete(:apikey)
      @reg_data = @server.registry.get(apikey) if apikey
      send({apikeyack: false}) if apikey && !@reg_data
      send({apikeyack: true}) if apikey && @reg_data
      yield msg if msg != {}
    end
  end
  def send(msg)
    @socket.write(msg.to_json + "\r\n")
    @log.info { "Send to client: #{msg}" }
  end
end

class JSONServerClientRegistry
  def initialize(file_name)
    @store = YAML::Store.new(file_name)
  end
  def add(data)
    key = nil
    @store.transaction do
      begin
        key = SecureRandom.uuid
      end while @store.root?(key)
      @store[key] = data
    end
    return key
  end
  def get(key)
    entry = nil
    @store.transaction(true) do
      entry = @store[key]
    end
    return entry
  end
  def edit(key)
    @store.transaction do
      yield @store[key]
    end
  end
end
