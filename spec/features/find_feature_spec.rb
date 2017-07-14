describe 'Crm.find features' do
  let(:contact) do
    Crm::Contact.create({
      first_name: 'Jon',
      gender: 'N',
      language: 'de',
      last_name: "Doe #{SecureRandom.hex(14)}",
    })
  end
  let(:account) do
    Crm::Account.create({
      name: "Great #{SecureRandom.hex(14)} Company Inc.",
      street_address: 'Main street 5',
    })
  end

  context 'with several IDs of different types' do
    it 'returns list of items in the requested order' do
      result = Crm.find([contact.id, account.id])
      expect(result.map(&:id)).to eq([contact.id, account.id])
      expect(result.map(&:class)).to eq([Crm::Contact, Crm::Account])

      enumerator = result.each
      expect(enumerator.next.first_name).to eq('Jon')
      expect(enumerator.next.street_address).to eq('Main street 5')
    end
  end

  context 'with one id' do
    it 'returns that item' do
      result = Crm.find(contact.id)
      expect(result).to be_a(Crm::Contact)
      expect(result.first_name).to eq('Jon')
    end
  end
end
