require 'action_dispatch'

module Crm; module Core
  class LogSubscriber < ActiveSupport::LogSubscriber
    def logger
      self.class.logger.presence or super
    end

    def request(event)
      info { "#{event.payload[:method].to_s.upcase} #{event.payload[:resource_path]}" }
      request_payload = event.payload[:request_payload]
      if request_payload.present?
        debug { "  request body: #{parameter_filter.filter(request_payload)}" }
      end
    end

    def response(event)
      r = event.payload[:response]
      info {
        "  #{r.code} #{r.message} #{r.body.to_s.length} (total: #{event.duration.round(1)}ms)"
      }
      debug {
        response_payload = MultiJson.load(r.body)
        "  response body: #{parameter_filter.filter(response_payload)}"
      }
    end

    def establish_connection(event)
      debug {
        attempt = event.payload[:attempt]
        "  Establishing connection on attempt #{attempt} (#{event.duration.round(1)}ms)"
      }
    end

    private

    def parameter_filter
      @parameter_filter ||= ::ActionDispatch::Http::ParameterFilter.new(['password'])
    end
  end
end; end
