require 'spec_helper'

describe 'event contact features' do
  before(:all) { CrmSetup.define_base_event }

  let(:now) { Time.now.utc.xmlschema }
  let(:event) {
    Crm::Event.create({
      dtstart_at: now,
      dtend_at: now,
      title: 'My Event',
      attribute_definitions: {
        'custom_food_preference' => {
          'title' => 'Food preference',
          'type' => 'enum',
          'mandatory' => false,
          'valid_values' => ['meat', 'vegetarian', 'vegan'],
        },
      },
      type_id: 'base-event',
    })
  }
  let(:contact) {
    Crm::Contact.create({
      gender: 'M',
      language: 'en',
      last_name: 'Jonson',
    })
  }

  describe 'create' do
    it 'creates under certain conditions' do
      # try to create event contact with incomplete attributes
      expect {
        Crm::EventContact.create({})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      # create event contact
      event_contact = Crm::EventContact.create({
        event_id: event.id,
        contact_id: contact.id,
        state: 'registered',
        custom_food_preference: 'meat'
      })
      expect(event_contact.id).to be_present
      expect(event_contact.event_id).to eq(event.id)
      expect(event_contact.contact_id).to eq(contact.id)
      expect(event_contact.state).to eq('registered')
      expect(event_contact.custom_food_preference).to eq('meat')
    end
  end

  describe 'find' do
    let(:event_contact) {
      Crm::EventContact.create({
        event_id: event.id,
        contact_id: contact.id,
        state: 'registered',
      })
    }

    it 'finds under certain conditions' do
      # find event contact with wrong ID fails with "ResourceNotFound"
      expect {
        Crm::EventContact.find('non-existing')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # find event contact
      expect(Crm::EventContact.find(event_contact.id).state).to eq('registered')
      expect(Crm::EventContact.find(event_contact.id).id).to eq(event_contact.id)
    end
  end

  describe 'update' do
    let(:event_contact) {
      Crm::EventContact.create({
        event_id: event.id,
        contact_id: contact.id,
        state: 'registered',
      })
    }
    let!(:outdated_event_contact) { Crm::EventContact.find(event_contact.id) }

    it 'updates under certain conditions' do
      # try to update event contact with incomplete attributes
      expect {
        event_contact.update(state: '')
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        event_contact.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update event contact
      event_contact.update(state: 'attended')
      expect(event_contact.state).to eq('attended')
      expect(event_contact.version).to eq(2)
      expect(Crm::EventContact.find(event_contact.id).state).to eq('attended')

      # optimistic locking for update
      expect{
        outdated_event_contact.update(state: 'refused')
      }.to raise_error(Crm::Errors::ResourceConflict)
    end
  end

  describe 'delete' do
    let(:event_contact) {
      Crm::EventContact.create({
        event_id: event.id,
        contact_id: contact.id,
        state: 'registered',
      })
    }
    let!(:outdated_event_contact) { Crm::EventContact.find(event_contact.id) }

    before do
      event_contact.update(state: 'refused')
    end

    it 'deletes under certain conditions' do
      # optimistic locking for delete
      expect{
        outdated_event_contact.delete
      }.to raise_error(Crm::Errors::ResourceConflict)

      # delete event contact
      expect(event_contact).to_not be_deleted
      event_contact.delete
      expect(event_contact).to be_deleted
      expect(Crm::EventContact.find(event_contact.id)).to be_deleted

      # fail, when precondition not met
      expect{ event_contact.delete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'undelete' do
    let(:event_contact) {
      Crm::EventContact.create({
        event_id: event.id,
        contact_id: contact.id,
        state: 'registered',
      })
    }

    before do
      event_contact.delete
    end

    it 'undeletes under certain conditions' do
      expect(event_contact).to be_deleted
      event_contact.undelete
      expect(event_contact).to_not be_deleted
      expect(Crm::EventContact.find(event_contact.id)).to_not be_deleted

      # fail, when precondition not met
      expect {
        event_contact.undelete
      }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'changes' do
    let(:event_contact) {
      Crm::EventContact.create({
        event_id: event.id,
        contact_id: contact.id,
        state: 'registered',
      })
    }

    before do
      event_contact.delete
    end

    it 'looks for changes' do
      changes = event_contact.changes
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
    it 'returns the first event contact' do
      event_contact = Crm::EventContact.first
      expect(event_contact).to be_a(Crm::EventContact)
      expect(event_contact.base_type).to eq('EventContact')
      expect(event_contact.created_at).to be_present
    end
  end
end
