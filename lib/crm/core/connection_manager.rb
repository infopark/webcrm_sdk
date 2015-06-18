module Crm; module Core
  class ConnectionManager
    SOCKET_ERRORS = [
      EOFError,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      IOError,
      SocketError,
      Timeout::Error,
    ].freeze

    DEFAULT_TIMEOUT = 10.freeze

    attr_reader :uri
    attr_reader :ca_file
    attr_reader :cert_store

    def initialize(uri)
      @uri = uri
      @ca_file = File.expand_path('../../../../config/ca-bundle.crt', __FILE__)
      @cert_store = OpenSSL::X509::Store.new.tap do |store|
        store.set_default_paths
        store.add_file(@ca_file)
      end
      @connection = nil
    end

    def request(request, timeout=DEFAULT_TIMEOUT)
      request['User-Agent'] = user_agent
      ensure_started(timeout)

      begin
        @connection.request(request)
      rescue *SOCKET_ERRORS => e
        ensure_finished
        raise Errors::NetworkError.new(e.message, e)
      end
    end

    private

    def ensure_started(timeout)
      if @connection && @connection.started?
        configure_timeout(@connection, timeout)
      else
        conn = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == 'https'
          conn.use_ssl = true
          conn.verify_mode = OpenSSL::SSL::VERIFY_PEER
          conn.cert_store = @cert_store
        end
        configure_timeout(conn, timeout)
        retry_twice_on_socket_error do |attempt|
          ActiveSupport::Notifications.instrument("establish_connection.crm") do |msg|
            msg[:attempt] = attempt
            conn.start
          end
        end
        @connection = conn
      end
    end

    def ensure_finished
      @connection.finish if @connection && @connection.started?
      @connection = nil
    end

    def retry_twice_on_socket_error
      attempt = 1
      begin
        yield attempt
      rescue *SOCKET_ERRORS => e
        raise Errors::NetworkError.new(e.message, e) if attempt > 2
        attempt += 1
        retry
      end
    end

    def configure_timeout(connection, timeout)
      connection.open_timeout = timeout
      connection.read_timeout = timeout
      connection.ssl_timeout = timeout
    end

    def user_agent
      @user_agent ||= (
        gem_info = Gem.loaded_specs["infopark_webcrm_sdk"]
        if gem_info
          "#{gem_info.name}-#{gem_info.version}"
        end
      )
    end
  end
end; end
