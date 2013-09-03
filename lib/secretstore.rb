require 'yaml/store'
require 'openssl'
require 'base64'

class SecretStore
  READ_ONLY = true
  def initialize(path)
    @store = YAML::Store.new path, true  # Be thread safe; though perhaps more cleanly handled if done by methods that use it...
  end
  def add(id, data=nil)
    @store.transaction do
      return false if @store.root?(id)
      @store[id] = {secret: nil, data: data}
    end
    return true
  end
  def reset(id)
    @store.transaction() do
      return false if !@store.root?(id)
      @store[id][:secret] = nil
    end
    return true
  end
  def auth?(id, secret)
    secret_digest = digest secret
    @store.transaction(READ_ONLY) do
      return false if !@store.root?(id)
      @store.abort if @store[id][:secret] == nil
      return @store[id][:secret] == secret_digest
    end
    @store.transaction() do
      return false if !@store.root?(id)
      @store[id][:secret] = secret_digest
    end
    return true
  end
  def exists?(id)
    @store.transaction(READ_ONLY) do
      return @store.root?(id)
    end
  end
  def remove(id)
    @store.transaction do
      return false if !@store.root?(id)
      @store.delete id
    end
    return true
  end
  def attach(id, data)
    @store.transaction do
      return false if !@store.root?(id)
      @store[id][:data] = data
    end
    return true
  end
  def view(id)
    data = nil
    @store.transaction(READ_ONLY) do
      data = @store[id][:data] if @store.root?(id)
    end
    return data
  end
  def digest(string)
    return Base64.strict_encode64 OpenSSL::Digest::SHA512.digest string
  end
end
