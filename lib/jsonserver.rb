require 'logger'
require 'socket'
require 'json'
require 'yaml/store'
require 'securerandom'
require 'openssl'

class JSONServerException < RuntimeError; end
class JSONServerClientRegistryDuplicateUIDError < JSONServerException; end
class JSONServerClientRegistryNonexistentUIDError < JSONServerException; end

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
    @auth = nil
    @log.info { "New connection #{@socket}" }
  end
  def receive()
    @socket.each do |line|
      line.strip!
      begin
        msg = JSON::parse(line, {:symbolize_names => true})
      rescue Exception => error
        @log.error { "Client message gave error #{error}" }
        send({error: error})
        msg = {}
      end
      if auth = msg.delete(:auth)
        uid = nil
        begin
          uid = auth[:uid]
          auth_result = @server.registry.auth(uid, auth[:key])
        rescue Exception => error
          @log.error { "Client auth request gave error #{error}" }
          send({error: error})
        end
        @auth = auth_result
        if auth_result
          @log.info { "Client authenticated as #{@auth}" }
        else
          @log.warn { "Client failed to authenticate as #{uid}" }
        end
        send({auth: @auth})
      end
      if msg != {}
        @log.info { "Client command: #{msg}" }
        begin
          yield msg
        rescue Exception => error
          @log.error { "Client message handler gave error #{error}" }
          send({error: error})
          raise error if $DEBUG
        end
      end
    end
  end
  def send(msg)
    @socket.write(msg.to_json + "\r\n")
    @log.info { "Send to client: #{msg}" }
  end
  attr_reader :auth
end

class JSONServerClientRegistry
  def initialize(file_name, default_length = 32, default_digest = 'sha512')
    File.open(file_name, "w") if !File.exist?(file_name)
    @store = YAML::Store.new(file_name, true)
    @default_length = default_length
    @default_digest = default_digest
  end
  def create(uid, length = @default_length, digest = @default_digest)
    uid = uid.to_sym
    raise JSONServerClientRegistryDuplicateUIDError.new if uid?(uid)
    key = SecureRandom.urlsafe_base64(length)
    hashed_key = OpenSSL::Digest.digest(digest, key)
    @store.transaction do
      @store[uid] = {digest:digest, hashed_key:hashed_key}
    end
    return key
  end
  def uid?(uid)
    uid = uid.to_sym
    exists = nil
    @store.transaction(true) do
      exists = @store.root?(uid.to_sym)
    end
    return exists
  end
  def uids()
    uids = nil
    @store.transaction(true) do
      uids = @store.roots
    end
    return uids
  end
  def auth(uid, key)
    uid = uid.to_sym
    authed = false
    @store.transaction(true) do
      return if !@store.root?(uid)
      entry = @store[uid]
      hashed_key = OpenSSL::Digest.digest(entry[:digest], key)
      authed = (hashed_key == entry[:hashed_key])
    end
    return authed ? uid : nil
  end
  def delete(uid)
    uid = uid.to_sym
    raise JSONServerClientRegistryNonexistentUIDError.new if !uid?(uid)
    @store.transaction do
      @store.delete(uid)
    end
  end
end
