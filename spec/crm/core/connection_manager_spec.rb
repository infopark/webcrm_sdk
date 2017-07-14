module Crm; module Core

describe ConnectionManager do
  let(:uri) { double URI, :host => 'localhost', :port => 3003, :scheme => 'http' }
  let(:https_uri) { double URI, :host => 'localhost', :port => 3003, :scheme => 'https' }

  let(:connection) do
    conn = double Net::HTTP
    class << conn
      attr_accessor :started, :read_timeout, :open_timeout, :ssl_timeout
      def started?() started end
      def start(*args)
        self.started = true
      end
    end
    conn
  end

  let(:mock_response) do
    double(Net::HTTPResponse, :code => '200', :body => '{}').tap do |r|
      allow(r).to receive(:[]).with("Retry-After").and_return "17.41"
    end
  end

  let(:request) { Net::HTTP::Get.new('/test_path') }

  subject { ConnectionManager.new(uri) }

  before do
    allow(Net::HTTP).to receive(:new).with('localhost', 3003).and_return connection
  end

  describe '#ca_file' do
    it 'provides a valid ca-bundle' do
      expect(File.read(subject.ca_file)).to include('-----BEGIN CERTIFICATE-----')
    end
  end

  describe '#cert_store' do
    let!(:cert_store) { OpenSSL::X509::Store.new }
    let!(:ca_file) { ConnectionManager.new(uri).ca_file }

    it 'uses system default certs and adds ca_file' do
      expect(OpenSSL::X509::Store).to receive(:new).and_return(cert_store)
      expect(cert_store).to receive(:set_default_paths).and_call_original
      expect(cert_store).to receive(:add_file).with(ca_file).and_call_original

      expect(ConnectionManager.new(uri).cert_store).to be(cert_store)
    end
  end

  describe '#request' do
    describe 'handling socket and server errors' do
      before do
        connection.started = true
      end

      context 'when a sockets error occurs' do
        it 'raises error as a NetworkError and resets connection' do
          allow(connection).to receive(:request) do
            expect(connection).to receive(:finish)
            raise Errno::ECONNRESET
          end

          expect { subject.request(request) }.to raise_error(Errors::NetworkError) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to_not be_a Errors::ClientError
            expect(error).to_not be_a Errors::ServerError

            expect(error.message).to eq('Connection reset by peer')
            expect(error.cause).to be_a Errno::ECONNRESET
          end
        end
      end

      context 'when a general error occurs' do
        it 'raises the plain error and does not reset connection' do
          allow(connection).to receive(:request) do
            expect(connection).to_not receive(:finish)
            raise 'random123'
          end

          expect { subject.request(request) }.to raise_error('random123')
        end
      end

      context 'connection is not started' do
        before{ connection.started = false }

        it 'should not finish connection error' do
          # On first try the connection gets started!
          expect(connection).to receive(:finish).once
          allow(connection).to receive(:request) do
            raise Errno::ECONNRESET
          end

          expect { subject.request(request) }.to raise_error(Errors::NetworkError) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to_not be_a Errors::ClientError
            expect(error).to_not be_a Errors::ServerError

            expect(error.message).to eq('Connection reset by peer')
            expect(error.cause).to be_a Errno::ECONNRESET
          end
        end
      end
    end

    context 'with a started connection' do
      before do
        connection.started = true
      end

      it 'should set the user agent header' do
          allow(connection).to receive(:request) do |received_request|
            expect(received_request['User-Agent']).to match(/^infopark_webcrm_sdk-([0-9a-z]+\.)+[0-9a-z]+$/)
            mock_response
          end

          subject.request(request)
      end

      it 'should set timeout on each request' do
        allow(connection).to receive(:request).and_return(mock_response)

        expect(connection).to receive(:open_timeout=).with(20)
        expect(connection).to receive(:read_timeout=).with(20)
        expect(connection).to receive(:ssl_timeout=).with(20)

        subject.request(request, 20)

        expect(connection).to receive(:open_timeout=).with(15)
        expect(connection).to receive(:read_timeout=).with(15)
        expect(connection).to receive(:ssl_timeout=).with(15)

        subject.request(request, 15)
      end
    end

    context 'with no connection' do
      it 'should start connection and set timeout' do
        allow(connection).to receive(:request).and_return(mock_response)
        expect(connection).to receive(:start)
        expect(connection).to receive(:read_timeout=).with(5)
        expect(connection).to receive(:open_timeout=).with(5)
        expect(connection).to receive(:ssl_timeout=).with(5)

        subject.request(request, 5)
      end
    end

    context 'with a not started connection' do
      before do
        allow(connection).to receive(:request).and_return(mock_response)
        subject.request(request)
        connection.started = false
      end

      it 'should start connection and set timeout' do
        expect(connection).to receive(:start)
        expect(connection).to receive(:read_timeout=).with(5)
        expect(connection).to receive(:open_timeout=).with(5)
        expect(connection).to receive(:ssl_timeout=).with(5)

        subject.request(request, 5)
      end

      describe 'when handling socket errors on start' do
        it 'should retry if error occurs at most twice' do
          attempt = 0
          allow(connection).to receive(:start) do
            if attempt < 2
              attempt += 1
              raise Errno::ECONNRESET
            end
          end
          subject.request(request)
        end

        it 'should raise error if it occurs more than twice' do
          allow(connection).to receive(:start) { raise Errno::ECONNRESET }

          expect { subject.request(request) }.to raise_error(Errors::NetworkError) do |error|
            expect(error).to be_a Errors::BaseError
            expect(error).to_not be_a Errors::ClientError
            expect(error).to_not be_a Errors::ServerError

            expect(error.message).to eq('Connection reset by peer')
            expect(error.cause).to be_a Errno::ECONNRESET
          end
        end
      end
    end

    context 'with a started connection' do
      before do
        allow(connection).to receive(:request).and_return(mock_response)

        subject.request(request)
      end

      it 'should reuse connection' do
        expect(Net::HTTP).to_not receive(:new)
        expect(connection).to_not receive(:start)

        3.times { subject.request(request) }
      end
    end

    context 'with ssl connection' do
      subject { ConnectionManager.new(https_uri) }

      it 'should configure connection to use ssl of required by config' do
        allow(connection).to receive(:request).and_return(mock_response)

        expect(connection).to receive(:use_ssl=).with(true).ordered
        expect(connection).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER).ordered
        expect(connection).to receive(:cert_store=).with(subject.cert_store)
        expect(connection).to receive(:start).ordered

        subject.request(request)
      end
    end
  end

end

end; end
