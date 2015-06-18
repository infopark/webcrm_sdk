require 'spec_helper'

describe 'activity features' do
  before(:all) { CrmSetup.define_support_case }

  describe 'create' do
    it 'creates under certain conditions' do
      # try to create activity with incomplete attributes
      expect {
        Crm::Activity.create({})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      # create activity
      activity = Crm::Activity.create({
        title: 'My Activity',
        type_id: 'support-case',
        state: 'created',
      })
      expect(activity.id).to be_present
      expect(activity.title).to eq('My Activity')
    end
  end

  describe 'find' do
    let(:activity) {
      Crm::Activity.create({
        title: 'My Activity',
        type_id: 'support-case',
        state: 'created',
      })
    }

    it 'finds under certain conditions' do
      # find activity with wrong ID fails with "ResourceNotFound"
      expect {
        Crm::Activity.find('non-existing')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # find activity
      expect(Crm::Activity.find(activity.id).id).to eq(activity.id)
      expect(Crm::Activity.find(activity.id).title).to eq('My Activity')
    end
  end

  describe 'update' do
    let(:activity) {
      Crm::Activity.create({
        title: 'My Activity',
        type_id: 'support-case',
        state: 'created',
      })
    }
    let!(:outdated_activity) { Crm::Activity.find(activity.id) }

    it 'updates under certain conditions' do
      # try to update activity with incomplete attributes
      expect {
        activity.update(title: '')
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        activity.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update activity
      activity.update(title: 'My other Activity')
      expect(activity.title).to eq('My other Activity')
      expect(activity.version).to eq(2)
      expect(Crm::Activity.find(activity.id).title).to eq('My other Activity')

      # optimistic locking for update
      expect{
        outdated_activity.update(title: 'Something else')
      }.to raise_error(Crm::Errors::ResourceConflict)
    end
  end

  describe 'delete' do
    let(:activity) {
      Crm::Activity.create({
        title: 'My Activity',
        type_id: 'support-case',
        state: 'created',
      })
    }
    let!(:outdated_activity) { Crm::Activity.find(activity.id) }

    before do
      activity.update(title: 'just change something')
    end

    it 'deletes under certain conditions' do
      # optimistic locking for delete
      expect{
        outdated_activity.delete
      }.to raise_error(Crm::Errors::ResourceConflict)

      # delete activity
      expect(activity).to_not be_deleted
      activity.delete
      expect(activity).to be_deleted
      expect(Crm::Activity.find(activity.id)).to be_deleted

      # fail, when precondition not met
      expect{ activity.delete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'undelete' do
    let(:activity) {
      Crm::Activity.create({
        title: 'My Activity',
        type_id: 'support-case',
        state: 'created',
      })
    }

    before do
      activity.delete
    end

    it 'undeletes under certain conditions' do
      expect(activity).to be_deleted
      activity.undelete
      expect(activity).to_not be_deleted
      expect(Crm::Activity.find(activity.id)).to_not be_deleted

      # fail, when precondition not met
      expect{ activity.undelete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'changes' do
    let(:activity) {
      Crm::Activity.create({
        title: 'My Activity',
        type_id: 'support-case',
        state: 'created',
      })
    }

    before do
      activity.delete
    end

    it 'looks for changes' do
      changes = activity.changes
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

  describe 'first' do
    it 'returns the first activity' do
      activity = Crm::Activity.first
      expect(activity).to be_a(Crm::Activity)
      expect(activity.base_type).to eq('Activity')
      expect(activity.created_at).to be_present
    end
  end
end
