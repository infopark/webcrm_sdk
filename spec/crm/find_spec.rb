module Crm

describe 'find' do
  context 'given IDs in an array' do
    it 'returns an ItemEnumerator with the requested IDs' do
      result = Crm.find(['abc', 'def'])
      expect(result).to be_a(Core::ItemEnumerator)
      expect(result.ids).to eq(['abc', 'def'])
    end
  end

  context 'given IDs as several parameters' do
    it 'returns an ItemEnumerator with the requested IDs' do
      result = Crm.find('abc', 'def')
      expect(result).to be_a(Core::ItemEnumerator)
      expect(result.ids).to eq(['abc', 'def'])
    end
  end

  context 'given one ID' do
    context 'inside an array' do
      it 'returns an ItemEnumerator with the requested ID' do
        result = Crm.find(['xyz'])
        expect(result).to be_a(Core::ItemEnumerator)
        expect(result.ids).to eq(['xyz'])
      end
    end

    context 'given as parameter' do
      it 'returns the single item' do
        item_double = double(Core::ItemEnumerator)
        expect(Core::ItemEnumerator).to receive(:new).with(['xyz']).and_return(item_double)
        expect(item_double).to receive(:first).and_return('activity')

        expect(Crm.find('xyz')).to eq('activity')
      end
    end
  end

  context 'with no ID' do
    it 'raises a ResourceNotFound error' do
      expect {Crm.find}.to raise_error(
          Crm::Errors::ResourceNotFound)
    end
  end

  context 'with nil ID' do
    it 'raises a ResourceNotFound error' do
      expect {Crm.find(nil)}.to raise_error(
          Crm::Errors::ResourceNotFound)
    end
  end
end

end
