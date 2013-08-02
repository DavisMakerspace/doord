require 'logger'
require 'socket'
require 'json'
require 'yaml/store'
require 'securerandom'

class JSONServer
  def initialize(server, keys, log = Logger.new(STDERR))
    @server = server
    @keys = keys
    @log = log
  end
  def accept()
    return JSONClient.new(self, @server.accept)
  end
  attr_reader :keys, :log
end

class JSONClient
  def initialize(server, socket)
    @server = server
    @socket = socket
    @log = @server.log
    @auth = nil
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
      @auth = @server.keys[apikey] if apikey
      send({error: "Invalid API key"}) if apikey && !@auth
      send({ack: "Welcome #{@auth.description}"}) if apikey && @auth
      yield msg if msg != {}
    end
  end
  def send(msg)
    @socket.write(msg.to_json + "\r\n")
    @log.info { "Send to client: #{msg}" }
  end
end

class JSONServerKeys
  def initialize(file_name)
    @yamlstore = YAML::Store.new(file_name)
  end
  def [](key)
    entry = nil
    @yamlstore.transaction(true) do
      entry = @yamlstore[key]
    end
    return entry
  end
  def add(entry)
    @yamlstore.transaction do
      @yamlstore[entry.key] = entry
    end
  end
end

class JSONServerKeyEntry
  include Comparable
  def self.generate(description = "", groups = [])
    return new(SecureRandom.uuid, description, groups)
  end
  def initialize(key, description, groups)
    @key = key
    @description = description
    @groups = groups
  end
  def <=>(key)
    return @key <=> key.key
  end
  attr_reader :key
  attr_accessor :description, :groups
end
