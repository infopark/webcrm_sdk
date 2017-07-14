module Crm; module Core

describe ItemEnumerator do
  let(:ids) { [] }
  let(:enumerator) { ItemEnumerator.new(ids) }

  it 'is an Enumerable' do
    expect(enumerator).to be_a Enumerable
  end

  describe '#inspect' do
    let(:item) { ItemEnumerator.new(['a', 'b', 'c'], total: 23) }

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(%|length=3, total=23>|)
    end
  end

  context 'with two IDs given' do
    let(:contact_attrs) do
      {
        'id' => 'abc',
        'base_type' => 'Contact',
        'first_name' => 'Jon',
      }
    end
    let(:account_attrs) do
      {
        'id' => 'def',
        'base_type' => 'Account',
        'street_address' => 'Main street 5',
      }
    end
    let(:ids) { [contact_attrs['id'], account_attrs['id']] }

    context 'with a block' do
      it 'yields the items in the requested order' do
        expect(Core::RestApi.instance).to receive(:get).with(
          'mget', { 'ids' => ['abc', 'def'] }
        ).and_return([contact_attrs, account_attrs])

        expected_items = [
          Crm::Contact.new(contact_attrs),
          Crm::Account.new(account_attrs),
        ]
        enumerator.each do |item|
          expect(item).to eq(expected_items.shift)
        end
        expect(expected_items).to be_empty
      end
    end

    context 'as an iterator' do
      it 'iterates the items in the requested order' do
        expect(Core::RestApi.instance).to receive(:get).with(
          'mget', { 'ids' => ['abc', 'def'] }
        ).and_return([contact_attrs, account_attrs])

        iterator = enumerator.each
        expect(iterator.next).to eq(Crm::Contact.new(contact_attrs))
        expect(iterator.next).to eq(Crm::Account.new(account_attrs))
        expect { iterator.next }.to raise_error(StopIteration)
      end
    end
  end

  context 'with 101 IDs given' do
    let(:ids) { ("0".."100").to_a }
    let(:server_response) do
      ids.map { |id| {'base_type' => 'Contact', 'id' => id} }
    end

    it 'yields the items with the requested IDs (requesting 100 items per batch)' do
      expect(Core::RestApi.instance).to receive(:get).with(
        'mget', { 'ids' => ids.take(100) }
      ).and_return(server_response.take(100))
      expect(Core::RestApi.instance).to receive(:get).with(
        'mget', { 'ids' => ids.drop(100) }
      ).and_return(server_response.drop(100))

      expected_items = ids.map { |id| Crm::Contact.new({'id' => id}) }
      enumerator.each do |item|
        expect(item).to eq(expected_items.shift)
      end
      expect(expected_items).to be_empty
    end
  end

  describe '#length and #size' do
    let(:ids) { ['a', 'b', 'c'] }

    it 'returns the number of items without requesting the server' do
      expect(Crm).to_not receive(:find)
      expect(enumerator.length).to eq(3)
      expect(enumerator.size).to eq(3)
    end
  end

  describe '#ids' do
    let(:ids) { ['a', 'b', 'c'] }

    it 'returns initialized IDs' do
      expect(enumerator.ids).to eq(ids)
    end
  end

  describe '#total' do
    let(:ids) { ['a', 'b', 'c'] }

    context 'when no total is explicitly given' do
      let(:enumerator) { ItemEnumerator.new(ids) }

      it 'returns the number of IDs' do
        expect(enumerator.total).to eq(3)
      end
    end

    context 'when a total is explicitly given' do
      let(:enumerator) { ItemEnumerator.new(ids, total: 23) }

      it 'returns the given total' do
        expect(enumerator.total).to eq(23)
      end
    end
  end
end

end; end
