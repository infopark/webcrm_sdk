module Crm; module Core
  # +Configuration+ is yielded by {Crm.configure}.
  # It lets you set the credentials for accessing the API.
  # The +tenant+, +login+, and +api_key+ attributes must be provided.
  # @api public
  class Configuration
    attr_reader :api_key
    attr_reader :login
    attr_reader :tenant

    attr_accessor :endpoint

    # @param value [String]
    # @return [void]
    # @api public
    attr_writer :api_key

    # @param value [String]
    # @return [void]
    # @api public
    attr_writer :login

    # @param value [String]
    # @return [void]
    # @api public
    attr_writer :tenant

    def endpoint_uri
      if endpoint.present?
        url = endpoint
        url = "https://#{url}" unless url.match(/^http/)
        url += '/' unless url.end_with?('/')
        URI.parse(url)
      else
        URI.parse("https://#{tenant}.crm.infopark.net/api2/")
      end
    end

    def logger
      Crm::Core::LogSubscriber.logger
    end

    # The {http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger.html logger} of the
    # JustRelate WebCRM SDK. It logs request URLs according to the +:info+ level.
    # Additionally, it logs request and response payloads according to the +:debug+ level.
    # Password fields are filtered out.
    # In a Rails environment, the logger defaults to +Rails.logger+. Otherwise, no logger is set.
    # @param value [Logger]
    # @return [void]
    # @api public
    # @!parse attr_writer :logger

    def logger=(logger)
      Crm::Core::LogSubscriber.logger = logger
    end

    def validate!
      raise "Missing required configuration key: api_key" if api_key.blank?
      raise "Missing required configuration key: login" if login.blank?
      if tenant.blank? && endpoint.blank?
        raise "Missing required configuration key: tenant"
      end
    end
  end
end; end
