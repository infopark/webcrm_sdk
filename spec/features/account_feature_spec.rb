require 'spec_helper'

describe 'account features' do
  describe 'create' do
    it 'creates under certain conditions' do
      # try to create account with incomplete attributes
      expect {
        Crm::Account.create({})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      # create account
      account = Crm::Account.create({name: 'My Company'})
      expect(account.id).to be_present
      expect(account.name).to eq('My Company')
      expect(account.created_at).to be_a(Time)
    end
  end

  describe 'find' do
    let(:account) { Crm::Account.create({name: 'My Company'}) }

    it 'finds under certain conditions' do
      # find account with wrong ID fails with "ResourceNotFound"
      expect {
        Crm::Account.find('non-existing')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # find account
      reloaded_account = Crm::Account.find(account.id)
      expect(reloaded_account.name).to eq('My Company')
      expect(reloaded_account.id).to eq(account.id)
      expect(reloaded_account.created_at).to be_a(Time)
    end
  end

  describe 'update' do
    let(:account) { Crm::Account.create({name: 'My Company'}) }
    let!(:outdated_account) { Crm::Account.find(account.id) }

    it 'updates under certain conditions' do
      # try to update account with incomplete attributes
      expect {
        account.update(name: '')
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        account.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update account
      account.update(name: 'Smith Inc.')
      expect(account.name).to eq('Smith Inc.')
      expect(account.version).to eq(2)
      expect(account.updated_at).to be_a(Time)
      reloaded_account = Crm::Account.find(account.id)
      expect(reloaded_account.name).to eq('Smith Inc.')
      expect(reloaded_account.updated_at).to be_a(Time)

      # optimistic locking for update
      expect{
        outdated_account.update(name: 'Something else')
      }.to raise_error(Crm::Errors::ResourceConflict)
    end
  end

  describe 'delete' do
    let(:account) { Crm::Account.create({name: 'My Company'}) }
    let!(:outdated_account) { Crm::Account.find(account.id) }

    before do
      account.update(name: 'just change something')
    end

    it 'deletes under certain conditions' do
      # optimistic locking for delete
      expect{
        outdated_account.delete
      }.to raise_error(Crm::Errors::ResourceConflict)

      # delete account
      expect(account).to_not be_deleted
      account.delete
      expect(account).to be_deleted
      expect(Crm::Account.find(account.id)).to be_deleted

      # fail, when precondition not met
      expect{ account.delete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'undelete' do
    let(:account) { Crm::Account.create({name: 'My Company'}) }

    before do
      account.delete
    end

    it 'undeletes under certain conditions' do
      expect(account).to be_deleted
      account.undelete
      expect(account).to_not be_deleted
      expect(Crm::Account.find(account.id)).to_not be_deleted

      # fail, when precondition not met
      expect{ account.undelete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'changes' do
    let(:account) { Crm::Account.create({name: 'My Company'}) }

    before do
      account.delete
    end

    it 'looks for changes' do
      changes = account.changes
      expect(changes.length).to eq(1)

      delete_change = changes.detect do |change|
        change.details.has_key?('deleted_at')
      end
      expect(delete_change.changed_at).to be_a(Time)
      expect(delete_change.changed_by).to eq('root')

      detail = delete_change.details['deleted_at']
      expect(detail.before).to be_nil
      expect(detail.after).to be_a(String)
    end
  end

  describe 'merge_and_delete' do
    let(:account) { Crm::Account.create({name: 'My Company'}) }
    let(:merge_into_account) { Crm::Account.create({name: 'My other Company'}) }

    it 'merges the account into merge_into_account and deletes it' do
      expect(account.merged_into_id).to eq('')
      expect(account).to_not be_deleted

      account.merge_and_delete(merge_into_account.id)

      expect(account.merged_into_id).to eq(merge_into_account.id)
      expect(account).to be_deleted

      expect(account.merged_into.name).to eq('My other Company')
    end
  end

  describe 'first' do
    it 'returns the first account' do
      account = Crm::Account.first
      expect(account).to be_a(Crm::Account)
      expect(account.base_type).to eq('Account')
      expect(account.created_at).to be_present
    end
  end
end
