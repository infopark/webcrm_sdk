describe 'ItemEnumerator features' do
  context 'with no IDs given' do
    it 'returns an empty array' do
      expect(Crm::Core::ItemEnumerator.new([]).to_a).to eq([])
    end
  end

  context 'with three different items' do
    let(:contact) {
      Crm::Contact.create({
        last_name: "Doe",
        gender: 'F',
        language: 'en',
      })
    }
    let(:account) { Crm::Account.create({name: 'Account Inc.'}) }
    let(:collection) {
      Crm::Collection.create({
        title: 'My Collection',
        collection_type: 'contact',
      })
    }
    let(:item_enumerator) {
      Crm::Core::ItemEnumerator.new([contact.id, account.id, collection.id])
    }

    it 'yields these three items' do
      expected_items = [contact, account, collection]
      item_enumerator.each do |item|
        expect(item).to eq(expected_items.shift)
      end
      expect(expected_items).to be_empty
    end
  end

  context 'with non existing IDs' do
    it 'raises an error' do
      expect {
        Crm::Core::ItemEnumerator.new(['nonexisting']).to_a
      }.to raise_error(Crm::Errors::ResourceNotFound) do |error|
        expect(error.message).to eq('Items could not be found. Missing IDs: nonexisting')
        expect(error.missing_ids).to eq(['nonexisting'])
      end
    end
  end

end
