require 'multi_json'
require 'addressable/uri'

module Crm; module Core
  class RestApi
    METHOD_TO_NET_HTTP_CLASS = {
      :get => Net::HTTP::Get,
      :put => Net::HTTP::Put,
      :post => Net::HTTP::Post,
      :delete => Net::HTTP::Delete,
    }.freeze

    def self.instance=(instance)
      @instance = instance
    end

    def self.instance
      if @instance
        @instance
      else
        raise "Please run Crm.configure first"
      end
    end

    def initialize(uri, login, api_key)
      @uri = uri
      @login = login
      @api_key = api_key
      @connection_manager = ConnectionManager.new(uri)
    end

    def get(resource_path, payload = nil)
      response_for_request(:get, resource_path, payload, {})
    end

    def put(resource_path, payload, headers = {})
      response_for_request(:put, resource_path, payload, headers)
    end

    def post(resource_path, payload)
      response_for_request(:post, resource_path, payload, {})
    end

    def delete(resource_path, payload = nil, headers = {})
      response_for_request(:delete, resource_path, payload, headers)
    end

    def resolve_uri(url)
      input_uri = Addressable::URI.parse(url)
      input_uri.path = Addressable::URI.escape(input_uri.path)
      @uri + input_uri.to_s
    end

    private

    def response_for_request(method, resource_path, payload, headers)
      path = resolve_uri(resource_path).path
      request = method_to_net_http_class(method).new(path)
      set_headers(request, headers)
      request.body = MultiJson.encode(payload) if payload.present?

      response = nil
      retried = false
      begin
        ActiveSupport::Notifications.instrument("request.crm") do |msg|
          msg[:method] = method
          msg[:resource_path] = "#{resource_path}"
          msg[:request_payload] = payload
        end
        response = ActiveSupport::Notifications.instrument("response.crm") do |msg|
          # lower timeout back to DEFAULT_TIMEOUT once the backend has been fixed
          msg[:response] = @connection_manager.request(request, 25)
        end
      rescue Errors::NetworkError => e
        if method == :post || retried
          raise e
        else
          retried = true
          retry
        end
      end

      handle_response(response)
    end

    def parse_payload(payload)
      MultiJson.load(payload)
    rescue MultiJson::DecodeError
      raise Errors::ServerError.new("Server returned invalid json: #{payload}")
    end

    def handle_response(response)
      body = parse_payload(response.body)
      if response.code.start_with?('2')
        body
      else
        message = body['message']

        case body['id']
        when 'unauthorized'
          raise Errors::UnauthorizedAccess.new(message)
        when 'authentication_failed'
          raise Errors::AuthenticationFailed.new(message)
        when 'forbidden'
          raise Errors::ForbiddenAccess.new(message)
        when 'not_found'
          raise Errors::ResourceNotFound.new(message, body['missing_ids'])
        when 'item_state_precondition_failed'
          raise Errors::ItemStatePreconditionFailed.new(message, body['unmet_preconditions'])
        when 'conflict'
          raise Errors::ResourceConflict.new(message)
        when 'invalid_keys'
          raise Errors::InvalidKeys.new(message, body['validation_errors'])
        when 'invalid_values'
          raise Errors::InvalidValues.new(message, body['validation_errors'])
        # leaving out 'params_parse_error', since the client should always send valid json.
        when 'rate_limit'
          raise Errors::RateLimitExceeded.new(message)
        when 'internal_server_error'
          raise Errors::ServerError.new(message)
        when 'too_many_params'
          raise Errors::TooManyParams.new(message)
        else
          if response.code == '404'
            raise Errors::ResourceNotFound.new('Not Found.')
          elsif response.code.start_with?('4')
            raise Errors::ClientError.new("HTTP Code #{response.code}: #{body}")
          else
            raise Errors::ServerError.new("HTTP Code #{response.code}: #{body}")
          end
        end
      end
    end

    def set_headers(request, additional_headers)
      request.basic_auth(@login, @api_key)
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      additional_headers.each do |key, value|
        request[key] = value
      end
    end

    def method_to_net_http_class(method)
      METHOD_TO_NET_HTTP_CLASS.fetch(method)
    end
  end
end; end
