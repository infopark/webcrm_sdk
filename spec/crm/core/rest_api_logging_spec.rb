require 'active_support/log_subscriber/test_helper'

module Crm; module Core

describe RestApi, 'logging' do
  let(:logger) { ActiveSupport::LogSubscriber::TestHelper::MockLogger.new }
  let(:connection_manager) { double(ConnectionManager) }

  before do
    RestApi.instance.instance_variable_set('@connection_manager', connection_manager)
  end

  around do |example|
    old_logger, LogSubscriber.logger = LogSubscriber.logger, logger
    example.run
    LogSubscriber.logger = old_logger
  end

  it "logs a short message to info and details to debug", :aggregate_failures do
    allow(connection_manager).to receive(:request).and_return(
        double(Net::HTTPResponse, code: '200', body: '[{"question": "answer"}]', message: 'OK'))
    RestApi.instance.get('/foo', [{'some' => 'payload'}])
    expect(logger.logged(:info)).to match([
      'GET /foo',
      /200 OK 24 \(total: 0\.\dms\)/,
    ])
    expect(logger.logged(:debug)).to eq([
      'request body: [{"some"=>"payload"}]',
      'response body: [{"question"=>"answer"}]',
    ])
  end

  it "filters sensitive parameters (e.g. 'password')", :aggregate_failures do
    allow(connection_manager).to receive(:request).and_return(
        double(Net::HTTPResponse, code: '200', body: '[{"new_password": "response_secret"}]', message: 'OK'))

    RestApi.instance.get('/foo', [{
      "password" => 'request_secret',
      "nested" => {"new_password" => 'request_secret'},
      "array" => [{"password2" => 'request_secret'}],
    }])
    expect(logger.logged(:info)).to match([
      "GET /foo",
      /200 OK 37 \(total: 0\.\dms\)/,
    ])
    expect(logger.logged(:debug)).to eq([
      'request body: [{"password"=>"[FILTERED]", "nested"=>{"new_password"=>"[FILTERED]"}, "array"=>[{"password2"=>"[FILTERED]"}]}]',
      'response body: [{"new_password"=>"[FILTERED]"}]',
    ])
  end
end

end; end
