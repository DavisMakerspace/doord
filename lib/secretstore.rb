require 'yaml/store'
require 'openssl'
require 'base64'

class SecretStore
  CRYPT_ITER = 20000
  DIGEST = OpenSSL::Digest::SHA512
  SALT_BYTES = 16
  DISABLING_PREFIX = '!'
  def initialize(path)
    @store = YAML::Store.new path, true  # Be thread safe; though perhaps more cleanly handled if done by methods that use it...
    @store.ultra_safe = true
  end
  def add(id)
    @store.transaction do
      return false if @store.root?(id)
      @store[id] = {key: '', salt: ''}
    end
    return true
  end
  def remove(id)
    @store.transaction do
      return false if !@store.root?(id)
      @store.delete id
    end
    return true
  end
  def set(id, secret)
    salt = Base64.strict_encode64 OpenSSL::Random.random_bytes(SALT_BYTES)
    @store.transaction() do
      return false if !@store.root?(id)
      @store[id][:key] = make_key(secret, salt)
      @store[id][:salt] = salt
    end
    return true
  end
  def disable(id)
    @store.transaction() do
      return false if !@store.root?(id)
      return true if @store[id][:key].start_with?(DISABLING_PREFIX)
      @store[id][:key].prepend DISABLING_PREFIX
    end
    return true
  end
  def disabled?(id)
    @store.transaction() do
      return @store.root?(id) ? @store[id][:key].start_with?(DISABLING_PREFIX) : false
    end
  end
  def undisable(id)
    @store.transaction() do
      return false if !@store.root?(id)
      return true if !@store[id][:key].start_with?(DISABLING_PREFIX)
      @store[id][:key][0] = ''
    end
    return true
  end
  def auth?(id, secret)
    entry = nil
    @store.transaction(true) do
      entry = @store[id] if @store.root?(id)
    end
    return entry ? (entry[:key] == make_key(secret, entry[:salt])) : false
  end
  def exists?(id)
    @store.transaction(true) do
      return @store.root?(id)
    end
  end
  def make_key(secret, salt)
    digest = DIGEST.new
    return Base64.strict_encode64 OpenSSL::PKCS5.pbkdf2_hmac(secret, Base64.strict_decode64(salt), CRYPT_ITER, digest.digest_length, digest)
  end
end
