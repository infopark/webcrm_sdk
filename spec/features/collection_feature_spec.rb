describe 'collection features' do
  describe 'create' do
    it 'creates under certain conditions' do
      # try to create collection with incomplete attributes
      expect {
        Crm::Collection.create({})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      # create collection
      collection = Crm::Collection.create({
        title: 'My Collection',
        collection_type: 'contact',
      })
      expect(collection.id).to be_present
      expect(collection.title).to eq('My Collection')
      expect(collection.collection_type).to eq('contact')
    end
  end

  describe 'find' do
    let(:collection) {
      Crm::Collection.create({
        title: 'My Collection',
        collection_type: 'contact',
      })
    }

    it 'finds under certain conditions' do
      # find collection with wrong ID fails with "ResourceNotFound"
      expect {
        Crm::Collection.find('non-existing')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # find collection
      expect(Crm::Collection.find(collection.id).title).to eq('My Collection')
      expect(Crm::Collection.find(collection.id).id).to eq(collection.id)
    end
  end

  describe 'update' do
    let(:collection) {
      Crm::Collection.create({
        title: 'My Collection',
        collection_type: 'contact',
      })
    }
    let!(:outdated_account) { Crm::Collection.find(collection.id) }

    it 'updates under certain conditions' do
      # try to update collection with incomplete attributes
      expect {
        collection.update(title: '')
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        collection.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update collection
      collection.update(title: 'Another Collection')
      expect(collection.title).to eq('Another Collection')
      expect(collection.version).to eq(2)
      expect(Crm::Collection.find(collection.id).title).to eq('Another Collection')

      # optimistic locking for update
      expect{
        outdated_account.update(title: 'Something else')
      }.to raise_error(Crm::Errors::ResourceConflict)
    end
  end

  describe 'delete' do
    let(:collection) {
      Crm::Collection.create({
        title: 'My Collection',
        collection_type: 'contact',
      })
    }
    let!(:outdated_account) { Crm::Collection.find(collection.id) }

    before do
      collection.update(title: 'just change something')
    end

    it 'deletes under certain conditions' do
      # optimistic locking for delete
      expect{
        outdated_account.delete
      }.to raise_error(Crm::Errors::ResourceConflict)
      collection.delete
    end
  end

  describe 'changes' do
    let(:collection) {
      Crm::Collection.create({
        title: 'My Collection',
        collection_type: 'contact',
      })
    }

    before do
      collection.update({title: 'My Collection 2'})
    end

    it 'looks for changes' do
      changes = collection.changes
      expect(changes.length).to eq(1)

      change = changes.detect do |change|
        change.details.has_key?('title')
      end
      expect(change.changed_at).to be_a(Time)
      expect(change.changed_by).to eq('root')

      detail = change.details['title']
      expect(detail.before).to eq('My Collection')
      expect(detail.after).to eq('My Collection 2')
    end
  end

  describe 'compute' do
    let(:collection) {
      Crm::Collection.create({
        title: 'My Collection',
        collection_type: 'contact',
      })
    }

    it 'starts the computation' do
      expect(collection.computation_started_at).to be_nil
      expect(collection.output_ids_computed_at).to be_nil

      collection.compute

      Patience.try do
        collection.reload
        expect(collection.output_ids_computed_at).to be_present
      end
    end
  end

  describe 'output_ids and output_items' do
    let(:last_name) { "Smith #{SecureRandom.hex(6)}" }
    let!(:contact) {
      Crm::Contact.create({
        last_name: last_name,
        gender: 'M',
        language: 'en',
      })
    }
    let(:collection) {
      Crm::Collection.create({
        title: 'My Collection',
        collection_type: 'contact',
        filters: [[{field: 'contact.last_name', condition: 'equals', value: last_name}]]
      })
    }

    it 'fetches the output IDs and data' do
      expect(collection.output_ids_count).to eq(0)

      expect(collection.output_ids).to eq([])
      expect(collection.output_items.to_a).to eq([])

      collection.compute
      Patience.try(sleep: 1, timeout: 30) do
        if collection.output_ids_computed_at.present? && collection.output_ids_count == 0
          collection.compute
        else
          collection.reload
        end
        expect(collection.output_ids_computed_at).to be_present

        expect(collection.output_ids_count).to eq(1)

        expect(collection.output_ids).to eq([contact.id])
        expect(collection.output_items.to_a).to eq([contact])
      end
    end
  end

  describe 'first' do
    it 'returns the first collection' do
      collection = Crm::Collection.first
      expect(collection).to be_a(Crm::Collection)
      expect(collection.base_type).to eq('Collection')
      expect(collection.created_at).to be_present
    end
  end
end
