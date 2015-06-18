require 'spec_helper'

describe 'errors features' do
  context 'when sending too many parameters' do
    it 'raises a TooManyParams error' do
      params = Hash[(1..1001).map { |v| [v, v] }]
      expect{ Crm::Contact.create(params) }.to raise_error(Crm::Errors::TooManyParams)
    end
  end

  context 'when .find(nil)' do
    it 'raises a ResourceNotFound error' do
      expect{ Crm::Contact.find(nil) }.to raise_error(Crm::Errors::ResourceNotFound)
    end
  end

  context 'with incorrect api_key' do
    let!(:old_rest_api_singleton) { Crm::Core::RestApi.instance }
    before do
      Crm::Core::RestApi.instance = old_rest_api_singleton.dup
      Crm::Core::RestApi.instance.instance_variable_set('@api_key', 'is wrong')
    end
    after { Crm::Core::RestApi.instance = old_rest_api_singleton }

    it 'raises an UnauthorizedAccess error' do
      expect{ Crm.find('wrong') }.to raise_error(Crm::Errors::UnauthorizedAccess)
    end
  end

  context 'with incorrect login' do
    let!(:old_rest_api_singleton) { Crm::Core::RestApi.instance }
    before do
      Crm::Core::RestApi.instance = old_rest_api_singleton.dup
      Crm::Core::RestApi.instance.instance_variable_set('@login', 'is wrong')
    end
    after { Crm::Core::RestApi.instance = old_rest_api_singleton }

    it 'raises an UnauthorizedAccess error' do
      expect{ Crm.find('wrong') }.to raise_error(Crm::Errors::UnauthorizedAccess)
    end
  end
end
