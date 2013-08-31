require 'openssl'

class SSLAuthServer < OpenSSL::SSL::SSLServer
  def initialize(server, server_cert, server_key, clients_certs, require_client_auth: false)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.cert = OpenSSL::X509::Certificate.new(server_cert)
    ssl_context.key = OpenSSL::PKey::RSA.new(server_key)
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    ssl_context.verify_mode |= OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT if require_client_auth
    ssl_context.cert_store = OpenSSL::X509::Store.new
    clients_certs.each do |client_cert|
      ssl_context.cert_store.add_cert OpenSSL::X509::Certificate.new(client_cert)
    end
    super(server, ssl_context)
  end
end
