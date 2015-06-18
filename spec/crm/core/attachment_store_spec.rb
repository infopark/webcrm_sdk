require 'spec_helper'

module Crm; module Core

describe AttachmentStore do
  let!(:old_rest_api_singleton) { Core::RestApi.instance }
  before do
    Core::RestApi.instance = Core::RestApi.new(URI.parse('http://example.com/api2/'), nil, nil)
  end
  after { Core::RestApi.instance = old_rest_api_singleton }

  describe '.generate_upload_permission' do
    it 'provides a upload permission' do
      expect(Core::RestApi.instance).to receive(:post).with(
          'attachment_store/generate_upload_permission', {}).and_return({
        'url' => 'http://s3.com/da/url',
        'fields' => 'da fields',
        'upload_id' => 'da upload_id',
      })

      permission = AttachmentStore.generate_upload_permission
      expect(permission.url).to eq('http://s3.com/da/url')
      expect(permission.fields).to eq('da fields')
      expect(permission.upload_id).to eq('da upload_id')
    end

    context 'when the server responds only with a path' do
      it 'returns the path as an absolute url' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'attachment_store/generate_upload_permission', {}).and_return({
          'url' => '/da/url',
          'fields' => 'da fields',
          'upload_id' => 'da upload_id',
        })

        permission = AttachmentStore.generate_upload_permission
        expect(permission.url).to eq('http://example.com/da/url')
      end
    end
  end

  describe '.generate_download_url' do
    it 'creates a download url' do
      expect(Core::RestApi.instance).to receive(:post).with(
          'attachment_store/generate_download_url', {'attachment_id' => '2342'}).and_return({
        'url' => 'http://example.com/da/download/url',
      })

      expect(AttachmentStore.generate_download_url('2342')).to eq('http://example.com/da/download/url')
    end

    context 'when the server responds only with a path' do
      it 'returns the path as an absolute url' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'attachment_store/generate_download_url', {'attachment_id' => '2342'}).and_return({
          'url' => '/da/download/url',
        })

        expect(AttachmentStore.generate_download_url('2342')).to eq("http://example.com/da/download/url")
      end
    end
  end

  describe '.upload' do
    let(:uri) { URI.parse('https://example.com/upload') }
    let(:upload_permission) do
      AttachmentStore::Permission.new(uri, uri.to_s, {foo: 'bar'}, 'uploadid23')
    end
    let(:connection_manager) { double(Core::ConnectionManager) }

    context 'when the upload is successful' do
      it 'returns the new upload id' do
        expect(AttachmentStore).to receive(:generate_upload_permission).and_return(upload_permission)
        expect(Core::ConnectionManager).to receive(:new).with(uri).and_return(connection_manager)

        expect(connection_manager).to receive(:request) do |request_param|
          expect(request_param.path).to eq('/upload')

          Struct.new(:code).new("200")
        end

        expect(AttachmentStore.upload(File.new('README.md'))).to eq('uploadid23/README.md')
      end
    end

    context 'when the upload failed' do
      it 'raises a server error' do
        expect(AttachmentStore).to receive(:generate_upload_permission).and_return(upload_permission)
        expect(Core::ConnectionManager).to receive(:new).with(uri).and_return(connection_manager)

        expect(connection_manager).to receive(:request) do |request_param|
          expect(request_param.path).to eq('/upload')

          Struct.new(:code).new("400")
        end

        expect {
          AttachmentStore.upload(File.new('README.md'))
        }.to raise_error(Crm::Errors::ServerError)
      end
    end
  end
end

end; end
