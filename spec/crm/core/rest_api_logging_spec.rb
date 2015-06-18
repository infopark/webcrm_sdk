require 'spec_helper'
require 'active_support/log_subscriber/test_helper'

module Crm; module Core

describe RestApi, 'logging' do
  let(:logger) { ActiveSupport::LogSubscriber::TestHelper::MockLogger.new }
  let(:connection_manager) { double(ConnectionManager) }
  let!(:old_logger) { LogSubscriber.logger }

  before do
    LogSubscriber.logger = logger

    RestApi.instance.instance_variable_set('@connection_manager', connection_manager)

    allow(connection_manager).to receive(:request).and_return(
        double(Net::HTTPResponse, code: '200', body: '{"question": "answer"}', message: 'OK'))
  end

  after do
    LogSubscriber.logger = old_logger
  end

  it "logs a short message to info" do
    RestApi.instance.get('/foo', 'get payload')
    expect(logger.logged(:info).length).to eq(2)
    expect(logger.logged(:info).first).to eq('GET /foo')
    expect(logger.logged(:info).second).to match(/200 OK 22 \(total: 0\.\dms\)/)
  end

  it "logs more details to debug" do
    RestApi.instance.get('/foo', {'some' => 'payload'})
    expect(logger.logged(:debug).length).to eq(2)
    expect(logger.logged(:debug).first).to eq('request body: {"some"=>"payload"}')
    expect(logger.logged(:debug).second).to eq('response body: {"question"=>"answer"}')
  end

  it "filters sensitive parameters (e.g. 'password')" do
    allow(connection_manager).to receive(:request).and_return(
        double(Net::HTTPResponse, code: '200', body: '{"new_password": "secret"}', message: 'OK'))

    RestApi.instance.get('/foo', {
      password: 'secret',
      nested: {"new_password" => 'secret'},
      other_datatype: [{"password2" => 'secret'}],
    })
    logger.logged(:info).each do |info|
      expect(info).to_not include('secret')
    end
    logger.logged(:debug).each do |debug|
      expect(debug).to include('password')
      expect(debug).to_not include('secret')
    end
  end
end

end; end
