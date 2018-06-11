def resource_path
  'random_resource_path'
end

module Crm; module Core

describe RestApi do
  let(:api_path) {
    "/dummy-path/random_resource_path"
  }
  let(:login) { 'dummy-login' }
  let(:api_key) { 'dummy-key' }
  let(:rest_api) {
    RestApi.new(URI.parse('http://dummy-endpoint/dummy-path/'), login, api_key)
  }

  after do
    WebMock.disable!
    WebMock.allow_net_connect!
  end

  context 'when Crm is not yet configured' do
    let!(:old_singleton) { RestApi.instance }
    before { RestApi.instance = nil }
    after { RestApi.instance = old_singleton }

    it 'raises an error' do
      expect { RestApi.instance }.to raise_error('Please run Crm.configure first')
    end
  end

  context 'with stubbed connection manager' do
    let(:connection_manager) { double(ConnectionManager) }

    let(:body) { '{"expected_result": true}' }

    let(:mock_response) { double Net::HTTPResponse, :code => '200', :body => body, :[] => nil }

    let(:authorization_header) do
      encoded_user_password_pair = Base64.encode64("#{login}:#{api_key}")
      "Basic #{encoded_user_password_pair}".strip
    end

    shared_examples_for 'a request, that retries request once, on NetworkError' do
      context "when a NetworkError occurs once during request" do
        it "retries the request" do
          first_attempt = true

          allow(connection_manager).to receive(:request) do |request|
            if first_attempt
              first_attempt = false
              raise Errors::NetworkError.new('first request is broken')
            end

            mock_response
          end

          request_action
        end
      end

      context "when a NetworkError occurs multiple times" do
        it "raises it" do
          allow(connection_manager).to receive(:request) do |request|
            raise Errors::NetworkError.new('all requests are broken')
          end

          expect { request_action }.to raise_error(Errors::NetworkError) { |error|
            expect(error.message).to eq('all requests are broken')
          }
        end
      end

      context "when a random error occurs" do
        it "raises it right away" do
          call_count = 0
          allow(connection_manager).to receive(:request) do |request|
            call_count += 1
            raise "random error on #{call_count}. try"
          end

          expect { request_action }.to raise_error('random error on 1. try')
        end
      end
    end

    before do
      rest_api.instance_variable_set('@connection_manager', connection_manager)
    end

    describe '#get' do
      context 'without a payload' do
        it 'should perform a get request' do
          allow(connection_manager).to receive(:request) do |request, timout|
            expect(request).to be_a_kind_of(Net::HTTP::Get)
            expect(request.path).to eq(api_path)
            expect(request['Content-Type']).to eq('application/json')
            expect(request['Accept']).to eq('application/json')
            expect(request['Authorization']).to eq(authorization_header)
            mock_response
          end

          rest_api.get(resource_path)
        end

        it 'should decode json' do
          expect(connection_manager).to receive(:request).and_return(mock_response)

          expect(rest_api.get(resource_path)).to eq({
            "expected_result" => true
          })
        end
      end

      describe('with a payload') do
        let(:payload){ {test1: 1, test: 2} }

        it 'should convert payload to json' do
          expect(connection_manager).to receive(:request) do |request, timeout|
            expect(request.path).to eq(api_path)
            expect(MultiJson.load(request.body)).to eq(payload.stringify_keys)

            mock_response
          end

          rest_api.get(resource_path, payload)
        end
      end

      it_behaves_like 'a request, that retries request once, on NetworkError' do
        let(:request_action) { rest_api.get(resource_path) }
      end
    end

    describe '#delete' do
      context 'without a payload' do
        it 'should perform a delete request' do
          allow(connection_manager).to receive(:request) do |request, timout|
            expect(request).to be_a_kind_of(Net::HTTP::Delete)
            expect(request.path).to eq(api_path)
            expect(request['Content-Type']).to eq('application/json')
            expect(request['Accept']).to eq('application/json')
            expect(request['Authorization']).to eq(authorization_header)
            mock_response
          end

          rest_api.delete(resource_path)
        end
      end

      context 'with a payload' do
        let(:payload){ {test1: 1, test: 2} }

        it 'should convert payload to json' do
          expect(connection_manager).to receive(:request) do |request, timeout|
            expect(request.path).to eq(api_path)
            expect(MultiJson.load(request.body)).to eq(payload.stringify_keys)

            mock_response
          end

          rest_api.delete(resource_path, payload)
        end
      end

      context 'with headers' do
        it 'sets the additional headers' do
          allow(connection_manager).to receive(:request) do |request, timout|
            expect(request['Content-Type']).to eq('application/json')
            expect(request['Accept']).to eq('application/json')
            expect(request['Authorization']).to eq(authorization_header)
            expect(request['Foo']).to eq('Bar')

            mock_response
          end

          rest_api.delete(resource_path, nil, {'Foo' => 'Bar'})
        end
      end

      it_behaves_like 'a request, that retries request once, on NetworkError' do
        let(:request_action) { rest_api.delete(resource_path) }
      end
    end

    describe '#put' do
      context 'without a payload' do
        it 'should perform a put request' do
          allow(connection_manager).to receive(:request) do |request, timout|
            expect(request).to be_a_kind_of(Net::HTTP::Put)
            expect(request.path).to eq(api_path)
            expect(request['Content-Type']).to eq('application/json')
            expect(request['Accept']).to eq('application/json')
            expect(request['Authorization']).to eq(authorization_header)
            expect(request.body).to be_nil
            mock_response
          end

          rest_api.put(resource_path, nil)
        end

        it 'should decode json' do
          expect(connection_manager).to receive(:request).and_return(mock_response)

          expect(rest_api.put(resource_path, nil)).to eq({
            "expected_result" => true
          })
        end
      end

      context 'with a payload' do
        let(:payload){ {test1: 1, test: 2} }

        it 'should convert payload to json' do
          expect(connection_manager).to receive(:request) do |request, timeout|
            expect(request.path).to eq(api_path)
            expect(MultiJson.load(request.body)).to eq(payload.stringify_keys)

            mock_response
          end

          rest_api.put(resource_path, payload)
        end
      end

      context 'with headers' do
        it 'sets the additional headers' do
          allow(connection_manager).to receive(:request) do |request, timout|
            expect(request['Content-Type']).to eq('application/json')
            expect(request['Accept']).to eq('application/json')
            expect(request['Authorization']).to eq(authorization_header)
            expect(request['Foo']).to eq('Bar')

            mock_response
          end

          rest_api.put(resource_path, nil, {'Foo' => 'Bar'})
        end
      end

      it_behaves_like 'a request, that retries request once, on NetworkError' do
        let(:request_action) { rest_api.put(resource_path, nil) }
      end
    end

    describe '#post' do
      context 'without a payload' do
        it 'should perform a post request' do
          allow(connection_manager).to receive(:request) do |request, timout|
            expect(request).to be_a_kind_of(Net::HTTP::Post)
            expect(request.path).to eq(api_path)
            expect(request['Content-Type']).to eq('application/json')
            expect(request['Accept']).to eq('application/json')
            expect(request['Authorization']).to eq(authorization_header)
            expect(request.body).to be_nil
            mock_response
          end

          rest_api.post(resource_path, nil)
        end

        it 'should decode json' do
          expect(connection_manager).to receive(:request).and_return(mock_response)

          expect(rest_api.post(resource_path, nil)).to eq({
            "expected_result" => true
          })
        end
      end

      describe('with a payload') do
        let(:payload){ {test1: 1, test: 2} }

        it 'should convert payload to json' do
          expect(connection_manager).to receive(:request) do |request, timeout|
            expect(request.path).to eq(api_path)
            expect(MultiJson.load(request.body)).to eq(payload.stringify_keys)

            mock_response
          end

          rest_api.post(resource_path, payload)
        end
      end

      context "when a NetworkError occurs once during request" do
        it "raises it right away" do
          first_attempt = true

          allow(connection_manager).to receive(:request) do |request|
            if first_attempt
              first_attempt = false
              raise Errors::NetworkError.new('first request is broken')
            end

            mock_response
          end

          expect { rest_api.post(resource_path, nil) }.to raise_error(Errors::NetworkError) { |e|
            expect(e.message).to eq('first request is broken')
          }
        end
      end
    end

    describe '#resolve_uri' do
      [
        ['foo', '/dummy-path/foo'],
        ['/foo', '/foo'],
        ['bar/contains spaces', '/dummy-path/bar/contains%20spaces'],
        ['blub-bla', '/dummy-path/blub-bla'],
        ['blub_bla', '/dummy-path/blub_bla'],
        ['foo?Expires=jo%3D', '/dummy-path/foo?Expires=jo%3D'],
        ['foo?query=true#fragment', '/dummy-path/foo?query=true#fragment'],
        ['', '/dummy-path/'],
      ].each do |input, expected_result|
        it "encodes '#{input}' urls correctly" do
          expect(rest_api.resolve_uri(input).to_s).to eq("http://dummy-endpoint#{expected_result}")
        end
      end
    end
  end

  describe 'using webmock' do
    let(:api_url) { rest_api.resolve_uri('').to_s }

    describe 'error handling' do
      before { WebMock.enable! }

      context 'when api user authentication failed (unauthorized)' do
        let(:response_body) do
          %|{
            "id": "unauthorized",
            "message": "Please validate credentials and try again."
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").with(basic_auth: [login, api_key]).
              to_return(body: response_body, status: 401)
        end

        it 'raises a UnauthorizedAccess error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::UnauthorizedAccess) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('Please validate credentials and try again.')
          end
        end
      end

      context 'when contact authentication failed (authentication_failed)' do
        let(:response_body) do
          %|{
            "id": "authentication_failed",
            "message": "The provided credentials are wrong."
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 422)
        end

        it 'raises a AuthenticationFailed error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::AuthenticationFailed) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('The provided credentials are wrong.')
          end
        end
      end

      context 'when forbidden' do
        let(:response_body) do
          %|{
            "id": "forbidden",
            "message": "The provided credentials do not provide access to the specified resource."
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 403)
        end

        it 'raises a ForbiddenAccess error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::ForbiddenAccess) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq(
                'The provided credentials do not provide access to the specified resource.')
          end
        end
      end

      context 'when not found' do
        let(:response_body) do
          %|{
            "id": "not_found",
            "message": "Items could not be found.",
            "missing_ids": ["0815", "123", "abc"]
          }|
        end

        before do
          stub_request(:get, "#{api_url}mget").to_return(body: response_body, status: 404)
        end

        it 'raises a ResourceNotFound error' do
          expect {
            rest_api.get('mget', ['0815', '123', 'abc'])
          }.to raise_error(Errors::ResourceNotFound) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('Items could not be found. Missing IDs: 0815, 123, and abc')
            expect(error.missing_ids).to eq(['0815', '123', 'abc'])
          end
        end
      end

      context 'when item state precondition failed' do
        let(:response_body) do
          %|{
            "id": "item_state_precondition_failed",
            "message": "The action cannot be performed on the item.",
            "unmet_preconditions": [
              {
                "code": "deletable",
                "message": "The mailing cannot be deleted."
              },
              {
                "code": "is_internal_mailing",
                "message": "The mailing is not an internal mailing."
              }
            ]
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 422)
        end

        it 'raises a ItemStatePreconditionFailed error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::ItemStatePreconditionFailed) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('The action cannot be performed on the item. ' \
                'The mailing cannot be deleted. The mailing is not an internal mailing.')
            expect(error.unmet_preconditions).to eq(
              [
                {
                  "code" => "deletable",
                  "message" => "The mailing cannot be deleted.",
                },
                {
                  "code" => "is_internal_mailing",
                  "message" => "The mailing is not an internal mailing.",
                },
              ])
          end
        end
      end

      context 'when a conflict occurs' do
        let(:response_body) do
          %|{
            "id": "conflict",
            "message": "The item was changed by someone else."
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 412)
        end

        it 'raises a ResourceConflict error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::ResourceConflict) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('The item was changed by someone else.')
          end
        end
      end

      context 'when too many params are send' do
        let(:response_body) do
          %|{
            "id": "too_many_params",
            "message": "The request contains too many parameters."
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 422)
        end

        it 'raises a TooManyParams error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::TooManyParams) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('The request contains too many parameters.')
          end
        end
      end

      context 'when invalid keys are send' do
        let(:response_body) do
          %|{
            "id": "invalid_keys",
            "message": "Unknown keys specified.",
            "validation_errors": [
              {
                "attribute": "foo",
                "message": "foo is unknown"
              },
              {
                "attribute": "bar",
                "message": "bar is unknown"
              }
            ]
          }|
        end

        before do
          stub_request(:put, "#{api_url}0815").to_return(body: response_body, status: 422)
        end

        it 'raises a InvalidKeys error' do
          expect {
            rest_api.put('0815', {foo: 'bla', bar: 'blub'})
          }.to raise_error(Errors::InvalidKeys) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('Unknown keys specified. ' \
                'foo is unknown and bar is unknown.')
            expect(error.validation_errors).to eq([
              {
                "attribute" => "foo",
                "message" => "foo is unknown",
              },
              {
                "attribute" => "bar",
                "message" => "bar is unknown",
              }
            ])
          end
        end
      end

      context 'when invalid values are send' do
        let(:response_body) do
          %|{
            "id": "invalid_values",
            "message": "Validate the parameters and try again.",
            "validation_errors": [
              {
                "type": "blank",
                "attribute": "name",
                "message": "name is blank"
              },
              {
                "type": "blank",
                "attribute": "language",
                "message": "language is blank"
              }
            ]
          }|
        end

        before do
          stub_request(:put, "#{api_url}0815").to_return(body: response_body, status: 422)
        end

        it 'raises a InvalidValues error' do
          expect {
            rest_api.put('0815', {})
          }.to raise_error(Errors::InvalidValues) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('Validate the parameters and try again. ' \
                'name is blank and language is blank.')
            expect(error.validation_errors).to eq([
              {
                "type" => "blank",
                "attribute" => "name",
                "message" => "name is blank",
              },
              {
                "type" => "blank",
                "attribute" => "language",
                "message" => "language is blank",
              }
            ])
          end
        end
      end

      context 'when rate limit is exceeded' do
        let(:response_body) do
          %|{
            "id": "rate_limit",
            "message": "Your account reached the API rate limit. Please wait a few minutes before making new requests."
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 405)
        end

        it 'raises a RateLimitExceeded error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::RateLimitExceeded) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('Your account reached the API rate limit. ' \
                'Please wait a few minutes before making new requests.')
          end
        end
      end

      context 'when an internal server error occurs' do
        let(:response_body) do
          %|{
            "id": "internal_server_error",
            "message": "We have been notified about this issue, and we will take a look at it shortly."
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 500)
        end

        it 'raises a ServerError error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::ServerError) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to_not be_a Errors::ClientError

            expect(error.message).to eq(
                'We have been notified about this issue, and we will take a look at it shortly.')
          end
        end
      end

      context 'when invalid json is returned' do
        let(:response_body) do
          'We are sorry but something went wrong'
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 500)
        end

        it 'raises a ServerError error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::ServerError) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to_not be_a Errors::ClientError

            expect(error.message).to eq(
                'Server returned invalid json: We are sorry but something went wrong')
          end
        end
      end

      context 'when an unknown 404 occurs' do
        let(:response_body) do
          %|{
            "status": "404",
            "error": "Not Found"
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 404)
        end

        it 'raises a ClientError error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::ResourceNotFound) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('Not Found. Missing IDs: ')
            expect(error.missing_ids).to eq([])
          end
        end
      end

      context 'when an unknown 4** occurs' do
        let(:response_body) do
          %|{
            "foo": "bar"
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 400)
        end

        it 'raises a ClientError error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::ClientError) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to be_a Errors::ClientError

            expect(error.message).to eq('HTTP Code 400: {"foo"=>"bar"}')
          end
        end
      end

      context 'when an unknown 3** occurs' do
        let(:response_body) do
          %|{
            "foo": "bar"
          }|
        end

        before do
          stub_request(:get, "#{api_url}0815").to_return(body: response_body, status: 300)
        end

        it 'raises a ServerError error' do
          expect { rest_api.get('0815') }.to raise_error(Errors::ServerError) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to_not be_a Errors::ClientError

            expect(error.message).to eq('HTTP Code 300: {"foo"=>"bar"}')
          end
        end
      end
    end
  end
end

end; end
