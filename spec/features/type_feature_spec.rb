describe 'type features' do
  let(:type_id) { "my-activity-#{SecureRandom.hex(4)}" }

  describe 'create' do
    let(:type) do
      Crm::Type.create({
        id: type_id,
        item_base_type: 'Activity',
        attribute_definitions: {
          custom_foo: {
            attribute_type: "text",
            title: "My Foo",
          },
        },
      })
    end

    it 'creates under certain conditions' do
      # try to create type with incomplete attributes
      expect {
        Crm::Type.create({})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      # create type
      type
      expect(type.id).to eq(type_id)
      expect(type.item_base_type).to eq('Activity')
      expect(type.attribute_definitions.keys).to eq(['custom_foo'])
    end

    after do
      type.delete
    end
  end

  describe 'find' do
    let(:type) do
      Crm::Type.create({
        id: type_id,
        item_base_type: 'Activity',
      })
    end

    it 'finds under certain conditions' do
      # find type with wrong id fails with "ResourceNotFound"
      expect {
        Crm::Type.find('non-existing')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # find type
      expect(Crm::Type.find(type.id).item_base_type).to eq('Activity')
      expect(Crm::Type.find(type.id).id).to eq(type.id)
    end

    after do
      type.delete
    end
  end

  describe 'update' do
    let(:type) do
      Crm::Type.create({
        id: type_id,
        item_base_type: 'Activity',
      })
    end
    let!(:outdated_type) { Crm::Type.find(type.id) }

    it 'updates under certain conditions' do
      # try to update type with incomplete attributes
      expect {
        type.update(attribute_definitions: {
          doesnt_start_with_custom: {},
        })
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        type.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update type
      type.update(attribute_definitions: {
        custom_foo: {
          attribute_type: "text",
          title: "My Foo",
        },
      })
      expect(type.attribute_definitions.keys).to eq(['custom_foo'])
      expect(type.version).to eq(2)
      expect(Crm::Type.find(type.id).attribute_definitions.keys).to eq(['custom_foo'])

      # optimistic locking for update
      expect {
        outdated_type.update(attribute_definitions: {
          custom_bar: {
            attribute_type: "text",
            title: "My Bar",
          },
        })
      }.to raise_error(Crm::Errors::ResourceConflict)
    end

    after do
      type.delete
    end
  end

  describe 'delete' do
    let(:type) do
      Crm::Type.create({
        id: type_id,
        item_base_type: 'Activity',
      })
    end
    let!(:outdated_type) { Crm::Type.find(type.id) }

    before do
      type.update(attribute_definitions: {
        custom_foo: {
          attribute_type: "text",
          title: "My Foo",
        },
      })
    end

    it 'deletes under certain conditions' do
      # optimistic locking for delete
      expect{
        outdated_type.delete
      }.to raise_error(Crm::Errors::ResourceConflict)

      # delete type
      expect(type).to_not be_deleted
      type.delete
      expect(type).to be_deleted
      expect(Crm::Type.find(type.id)).to be_deleted

      # fail, when precondition not met
      expect{ type.delete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end
  end

  describe 'undelete' do
    let(:type) do
      Crm::Type.create({
        id: type_id,
        item_base_type: 'Activity',
      })
    end

    before do
      type.delete
    end

    it 'undeletes under certain conditions' do
      expect(type).to be_deleted
      type.undelete
      expect(type).to_not be_deleted
      expect(Crm::Type.find(type.id)).to_not be_deleted

      # fail, when precondition not met
      expect{ type.undelete }.to raise_error(Crm::Errors::ItemStatePreconditionFailed)
    end

    after do
      type.delete
    end
  end

  describe 'changes' do
    let(:type) do
      Crm::Type.create({
        id: type_id,
        item_base_type: 'Activity',
      })
    end

    before do
      type.delete
    end

    it 'looks for changes' do
      changes = type.changes
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

  describe 'all' do
    it 'lists all types' do
      result = Crm::Type.all
      expect(result.map(&:id)).to include('collection')
      expect(result.map(&:item_base_type)).to include('Collection')

      result_with_deleted  = Crm::Type.all(include_deleted: true)
      expect(result.count).to be <= result_with_deleted.count
    end
  end
end
