require 'active_support/log_subscriber/test_helper'

module Crm; module Core

describe Configuration do
  let(:configuration) { Configuration.new }

  describe '#validate!' do
    context 'without any settings' do
      it 'complains about the first missing key' do
        expect { configuration.validate! }.to raise_error(
          "Missing required configuration key: api_key"
        )
      end
    end

    context 'with partial settings missing' do
      it 'complains about the next missing key' do
        configuration.api_key = 'my_api_key'
        expect { configuration.validate! }.to raise_error(
          "Missing required configuration key: login"
        )

        configuration.login = 'my_login'
        expect { configuration.validate! }.to raise_error(
          "Missing required configuration key: tenant"
        )
      end
    end

    context 'with correct settings' do
      context 'with tenant set' do
        it 'accepts the settings' do
          configuration.tenant = 'my_tenant'
          configuration.login = 'my_login'
          configuration.api_key = 'my_api_key'

          expect { configuration.validate! }.to_not raise_error
        end
      end

      context 'with endpoint set' do
        it 'accepts the settings' do
          configuration.endpoint = 'my_endpoint'
          configuration.login = 'my_login'
          configuration.api_key = 'my_api_key'

          expect { configuration.validate! }.to_not raise_error
        end
      end
    end
  end

  describe '#endpoint_uri' do
    context 'with a given endpoint' do
      it 'returns a URI based on #endpoint=' do
        configuration.endpoint = 'http://example.com'
        expect(configuration.endpoint_uri).to be_an(URI)
      end

      it 'uses the given scheme' do
        configuration.endpoint = 'http://example.com'
        expect(configuration.endpoint_uri.scheme).to eq('http')
      end

      it 'sets https as default, when no scheme is given' do
        configuration.endpoint = 'example.com'
        expect(configuration.endpoint_uri.scheme).to eq('https')
      end

      it 'appends a / to the path, when needed' do
        configuration.endpoint = 'example.com/api'
        expect(configuration.endpoint_uri.path).to eq('/api/')

        configuration.endpoint = 'example.com/api/'
        expect(configuration.endpoint_uri.path).to eq('/api/')
      end
    end

    context 'without a given endpoint' do
      it 'uses the default based on the tenant name' do
        configuration.tenant = 'foo'
        expect(configuration.endpoint_uri).to eq(URI.parse('https://foo.crm.infopark.net/api2/'))

        configuration.tenant = 'bar'
        expect(configuration.endpoint_uri).to eq(URI.parse('https://bar.crm.infopark.net/api2/'))
      end
    end
  end

  describe '#logger' do
    it 'returns the logger of Crm::Core::LogSubscriber' do
      expect(configuration.logger).to be(Crm::Core::LogSubscriber.logger)
    end
  end

  describe '#logger=' do
    let(:logger) { ActiveSupport::LogSubscriber::TestHelper::MockLogger.new }

    it 'sets the logger of Crm::Core::LogSubscriber' do
      configuration.logger = logger
      expect(Crm::Core::LogSubscriber.logger).to be(logger)
    end
  end
end

end; end
