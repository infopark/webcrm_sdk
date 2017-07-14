describe 'event features' do
  before(:all) { CrmSetup.define_base_event }

  let(:now) { Time.now.utc.xmlschema }

  describe 'create' do
    it 'creates under certain conditions' do
      # try to create event with incomplete attributes
      expect {
        Crm::Event.create({})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      # create event
      event = Crm::Event.create({
        dtstart_at: now,
        dtend_at: now,
        title: 'My Event',
        attribute_definitions: {},
        type_id: 'base-event',
      })
      expect(event.id).to be_present
      expect(event.title).to eq('My Event')
    end
  end

  describe 'find' do
    let(:event) {
      Crm::Event.create({
        dtstart_at: now,
        dtend_at: now,
        title: 'My Event',
        attribute_definitions: {},
        type_id: 'base-event',
      })
    }

    it 'finds under certain conditions' do
      # find event with wrong ID fails with "ResourceNotFound"
      expect {
        Crm::Event.find('non-existing')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # find event
      expect(Crm::Event.find(event.id).title).to eq('My Event')
      expect(Crm::Event.find(event.id).id).to eq(event.id)
    end
  end

  describe 'update' do
    let(:event) {
      Crm::Event.create({
        dtstart_at: now,
        dtend_at: now,
        title: 'My Event',
        attribute_definitions: {},
        type_id: 'base-event',
      })
    }
    let!(:outdated_event) { Crm::Event.find(event.id) }

    it 'updates under certain conditions' do
      # try to update event with incomplete attributes
      expect {
        event.update(title: '')
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        event.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update event
      event.update(title: 'New Event Title')
      expect(event.title).to eq('New Event Title')
      expect(event.version).to eq(2)
      expect(Crm::Event.find(event.id).title).to eq('New Event Title')

      # optimistic locking for update
      expect{
        outdated_event.update(title: 'Something else')
      }.to raise_error(Crm::Errors::ResourceConflict)
    end
  end

  describe 'delete' do
    let(:event) {
      Crm::Event.create({
        dtstart_at: now,
        dtend_at: now,
        title: 'My Event',
        attribute_definitions: {},
        type_id: 'base-event',
      })
    }
    let!(:outdated_event) { Crm::Event.find(event.id) }

    before do
      event.update(title: 'just change something')
    end

    it 'deletes under certain conditions' do
      # optimistic locking for delete
      expect{
        outdated_event.delete
      }.to raise_error(Crm::Errors::ResourceConflict)

      # delete event
      expect(event).to_not be_deleted
      event.delete
      expect(event).to be_deleted
      expect(Crm::Event.find(event.id)).to be_deleted

      # fail, when precondition not met
      expect{ event.delete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'undelete' do
    let(:event) {
      Crm::Event.create({
        dtstart_at: now,
        dtend_at: now,
        title: 'My Event',
        attribute_definitions: {},
        type_id: 'base-event',
      })
    }

    before do
      event.delete
    end

    it 'undeletes under certain conditions' do
      expect(event).to be_deleted
      event.undelete
      expect(event).to_not be_deleted
      expect(Crm::Event.find(event.id)).to_not be_deleted

      # fail, when precondition not met
      expect{ event.undelete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'changes' do
    let(:event) {
      Crm::Event.create({
        dtstart_at: now,
        dtend_at: now,
        title: 'My Event',
        attribute_definitions: {},
        type_id: 'base-event',
      })
    }

    before do
      event.delete
    end

    it 'looks for changes' do
      changes = event.changes
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
    it 'returns the first event' do
      event = Crm::Event.first
      expect(event).to be_a(Crm::Event)
      expect(event.base_type).to eq('Event')
      expect(event.created_at).to be_present
    end
  end
end
