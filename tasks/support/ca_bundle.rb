require 'openssl'
require 'socket'
require 'uri'

class CaBundle
  def initialize(path)
    @path = path
  end

  def create
    ca_bundle_file = File.expand_path('../ca_bundle.pl', __FILE__)
    %x{#{ca_bundle_file} -u -p SERVER_AUTH:TRUSTED_DELEGATOR,MUST_VERIFY_TRUST #{@path}}
  end

  def verify(url)
    uri = URI.parse(url)
    context = OpenSSL::SSL::SSLContext.new
    context.ca_file = @path
    context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    tcp_socket = TCPSocket.new(uri.host, uri.port)
    ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, context)
    ssl_socket.connect # Raises an error if verification fails.
    true
  end
end
