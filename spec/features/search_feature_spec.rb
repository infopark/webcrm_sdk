describe 'search features' do
  before(:all) { CrmSetup.define_support_case }

  context 'when searching for multiple items' do
    let(:family_name) { "Johnson #{SecureRandom.hex(4)}" }
    let!(:jane) do
      Crm::Contact.create({
        language: 'en',
        first_name: 'Jane',
        last_name: family_name,
      })
    end
    let!(:jim) do
      Crm::Contact.create({
        language: 'en',
        first_name: 'Jim',
        last_name: family_name,
      })
    end
    let!(:john) do
      Crm::Contact.create({
        language: 'en',
        first_name: 'John',
        last_name: family_name,
      })
    end

    it 'searches for the requested items' do
      # search with query
      search_result = Crm.search(
        query: family_name[0..-2],
        sort_by: 'score'
      )
      expect(search_result).to be_a(Crm::Core::ItemEnumerator)
      expect(search_result.ids).to include(jane.id, jim.id, john.id)
      expect(search_result.total).to eq(3)

      # search "all"
      search_result = Crm.search(
        filters: [{field: 'last_name', condition: 'equals', value: family_name}],
        sort_by: 'first_name'
      )
      expect(search_result).to be_a(Crm::Core::ItemEnumerator)
      expect(search_result.ids).to eq([jane.id, jim.id, john.id])
      expect(search_result.total).to eq(3)

      # search the first two items
      search_result = Crm.search(
        filters: [{field: 'last_name', condition: 'equals', value: family_name}],
        sort_by: 'first_name',
        limit: 2
      )
      expect(search_result).to be_a(Crm::Core::ItemEnumerator)
      expect(search_result.ids).to eq([jane.id, jim.id])
      expect(search_result.total).to eq(3)

      # search the second and third item
      search_result = Crm.search(
        filters: [{field: 'last_name', condition: 'equals', value: family_name}],
        sort_by: 'first_name',
        offset: 1,
        limit: 2
      )
      expect(search_result).to be_a(Crm::Core::ItemEnumerator)
      expect(search_result.ids).to eq([jim.id, john.id])
      expect(search_result.total).to eq(3)
    end

    it 'searches using method chaining' do
      search_config = Crm::Contact.
        where('last_name', 'equals', family_name).
        sort_by('first_name').
        sort_order('desc').
        offset(1).
        unlimited

      # via #perform_search
      search_result = search_config.perform_search
      expect(search_result.total).to eq(3)
      expect(search_result).to be_a(Crm::Core::ItemEnumerator)
      expect(search_result.ids).to eq([jim.id, jane.id])

      # directly
      expect(search_config.total).to eq(3)
      expected_items = [jim, jane]
      search_config.each do |item|
        expect(item).to eq(expected_items.shift)
      end
      expect(expected_items).to be_empty

      expect(search_config.first).to eq(jim)
      expect(search_config.offset(0).take(2)).to eq([john, jim])

      # negated search
      search_config = Crm::Contact.
        where('last_name', 'equals', family_name).
        and_not('first_name', 'equals', 'Jim').
        sort_by('first_name')

      search_result = search_config.perform_search
      expect(search_result.total).to eq(2)
      expect(search_result).to be_a(Crm::Core::ItemEnumerator)
      expect(search_result.ids).to eq([jane.id, john.id])
    end
  end

  context 'when searching for items with a specific base types' do
    let(:locality) { "Berlin#{SecureRandom.hex(4)}" }
    let!(:contact) do
      Crm::Contact.create({
        language: 'en',
        last_name: 'Smith',
        locality: locality,
      })
    end
    let!(:account) do
      Crm::Account.create({
        name: 'Smith Inc.',
        locality: locality,
      })
    end
    let(:filters) { [{field: 'locality', condition: 'equals', value: locality}] }

    it 'searches for the requested items' do
      items = Crm.search(filters: filters, sort_by: 'base_type')
      expect(items).to be_a(Crm::Core::ItemEnumerator)
      expect(items.ids).to eq([account.id, contact.id])
    end
  end

  it 'complains about unsupported conditions' do
    expect {
      Crm.search(filters: [{field: 'last_name', condition: 'foo', value: '123'}])
    }.to raise_error(Crm::Errors::InvalidValues) do |error|
      expect(error.validation_errors.first['message']).to match(/condition 'foo' is not supported/)
    end
  end

  it 'complains about negative offset' do
    expect {
      Crm.search(offset: -1)
    }.to raise_error(Crm::Errors::InvalidValues) do |error|
      expect(error.validation_errors.first['message']).to eq("Offset is smaller than 0.")
    end
  end

  context 'Mixins::Searchable.all' do
    let!(:activity) {
      Crm::Activity.create({
        title: 'Find me!',
        type_id: 'support-case',
        state: 'created',
      })
    }

    before do
      activity.destroy
    end

    it 'lists all activities (with or without deleted)' do
      all_without_deleted = Crm::Activity.all
      all_with_deleted = Crm::Activity.all(include_deleted: true)

      expect(all_without_deleted).to be_a(Crm::Core::ItemEnumerator)
      expect(all_with_deleted).to be_a(Crm::Core::ItemEnumerator)

      expect(all_without_deleted.ids).to_not include(activity.id)
      expect(all_with_deleted.ids).to include(activity.id)

      expect(all_without_deleted.length).to be < all_with_deleted.length
    end
  end
end
