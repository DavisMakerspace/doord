require 'yaml/store'
require 'openssl'
require 'base64'

class TokenRegistryException < RuntimeError; end
class TokenRegistryDuplicateError < TokenRegistryException; end

class TokenRegistry
  def initialize(path)
    @store = YAML::Store.new path
    @sha512 = OpenSSL::Digest::SHA512.new
  end
  def add(token, data)
    digest = mkdigest token
    puts digest
    @store.transaction do
      raise TokenRegistryDuplicateError.new if @store.root?(digest) && @store[digest] != data
      @store[digest] = data
    end
  end
  def rm(token)
    digest = mkdigest token
    @store.transaction do
      @store.delete digest
    end
  end
  def get(token)
    digest = mkdigest token
    data = nil
    @store.transaction do
      data = @store[digest] if @store.root?(digest)
    end
    return data
  end
  def mkdigest(token)
    @sha512.reset
    return Base64.strict_encode64 @sha512.digest token
  end
end
