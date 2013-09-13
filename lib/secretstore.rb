require 'yaml/store'
require 'openssl'
require 'base64'

class SecretStore
  CRYPT_ITER = 20000
  DIGEST = OpenSSL::Digest::SHA512
  SALT_BYTES = 16
  DISABLING_PREFIX = '!'
  def initialize(path)
    @store = YAML::Store.new path, true # true for thread-safe
    @store.ultra_safe = true # protect against I/O errors
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
    @store.transaction() do
      return false if !@store.root?(id)
      @store[id][:key], @store[id][:salt] = make_key(secret)
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
    return entry ? (entry[:key] == make_key(secret, entry[:salt])[0]) : false
  end
  def exists?(id)
    @store.transaction(true) do
      return @store.root?(id)
    end
  end
  def make_key(secret, salt64=nil)
    salt = salt64==nil ? OpenSSL::Random.random_bytes(SALT_BYTES) : Base64.strict_decode64(salt64)
    digest = DIGEST.new
    key = OpenSSL::PKCS5.pbkdf2_hmac(secret, salt, CRYPT_ITER, digest.digest_length, digest)
    return [key,salt].map(){|v| Base64.strict_encode64 v}
  end
end
