describe 'contact features' do
  describe 'create' do
    it 'creates under certain conditions' do
      # try to create contact with incomplete attributes
      expect {
        Crm::Contact.create({})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      # create contact
      contact = Crm::Contact.create({
        language: 'en',
        last_name: 'Smith',
      })
      expect(contact.id).to be_present
      expect(contact.last_name).to eq('Smith')
    end
  end

  describe 'find' do
    let(:contact) {
      Crm::Contact.create({
        language: 'en',
        last_name: 'Smith',
      })
    }

    it 'finds under certain conditions' do
      # find contact with wrong ID fails with "ResourceNotFound"
      expect {
        Crm::Contact.find('non-existing')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # find contact
      expect(Crm::Contact.find(contact.id).id).to eq(contact.id)
      expect(Crm::Contact.find(contact.id).last_name).to eq('Smith')
    end
  end

  describe 'update' do
    let(:contact) {
      Crm::Contact.create({
        language: 'en',
        last_name: 'Smith',
      })
    }
    let!(:outdated_contact) { Crm::Contact.find(contact.id) }

    it 'updates under certain conditions' do
      # try to update contact with incomplete attributes
      expect {
        contact.update(last_name: '')
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        contact.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update contact
      contact.update(first_name: 'John')
      expect(contact.first_name).to eq('John')
      expect(contact.version).to eq(2)
      expect(Crm::Contact.find(contact.id).first_name).to eq('John')

      # optimistic locking for update
      expect{
        outdated_contact.update(first_name: 'Something else')
      }.to raise_error(Crm::Errors::ResourceConflict)
    end
  end

  describe 'delete' do
    let(:contact) {
      Crm::Contact.create({
        language: 'en',
        last_name: 'Smith',
      })
    }
    let!(:outdated_contact) { Crm::Contact.find(contact.id) }

    before do
      contact.update(last_name: 'just change something')
    end

    it 'deletes under certain conditions' do
      # optimistic locking for delete
      expect{
        outdated_contact.delete
      }.to raise_error(Crm::Errors::ResourceConflict)
      contact.delete
    end
  end

  describe 'changes' do
    let(:contact) {
      Crm::Contact.create({
        language: 'en',
        last_name: 'Smith',
        first_name: 'John',
      })
    }

    before do
      contact.update({first_name: 'Jane'})
    end

    it 'looks for changes' do
      changes = contact.changes
      expect(changes.length).to eq(1)

      change = changes.detect do |change|
        change.details.has_key?('first_name')
      end
      expect(change.changed_at).to be_a(Time)
      expect(change.changed_by).to eq('root')

      detail = change.details['first_name']
      expect(detail.before).to eq('John')
      expect(detail.after).to eq('Jane')
    end
  end

  it 'handles authentication (authenticate, set_password, etc.)' do
    login = "contact_feature_spec_#{SecureRandom.hex(4)}"
    contact = Crm::Contact.create({
      language: 'en',
      last_name: 'Smith',
      login: login,
      email: 'success@simulator.amazonses.com',
    })
    expect(contact.password_present).to eq(false)
    expect(contact.version).to eq(1)

    # login with incorrect credentials - no pw set
    expect {
      Crm::Contact.authenticate!(login, 'wrong_pw')
    }.to raise_error(Crm::Errors::AuthenticationFailed)
    expect(Crm::Contact.authenticate(login, 'wrong_pw')).to be_nil

    # set a password
    password = SecureRandom.hex(16)
    contact.set_password(password)

    expect(contact.password_present).to eq(true)
    expect(contact.version).to eq(2)

    # login with incorrect credentials - a pw is set
    expect {
      Crm::Contact.authenticate!(login, 'wrong_pw')
    }.to raise_error(Crm::Errors::AuthenticationFailed)
    expect(Crm::Contact.authenticate(login, 'wrong_pw')).to be_nil

    # login with correct credentials
    contact = Crm::Contact.authenticate!(login, password)
    expect(contact.last_name).to eq('Smith')
    expect(contact.password_present).to eq(true)

    contact = Crm::Contact.authenticate(login, password)
    expect(contact.last_name).to eq('Smith')
    expect(contact.password_present).to eq(true)

    # clear password
    contact.clear_password
    expect(contact.password_present).to eq(false)
    expect{
      Crm::Contact.authenticate!(login, password)
    }.to raise_error(Crm::Errors::AuthenticationFailed)
    expect(Crm::Contact.authenticate(login, password)).to be_nil

    # generate and set password by token
    token = contact.generate_password_token
    password = SecureRandom.hex(16)
    contact = Crm::Contact.set_password_by_token(password, token)
    expect(contact.last_name).to eq('Smith')
    expect(contact.password_present).to eq(true)
    contact = Crm::Contact.authenticate(login, password)
    expect(contact.last_name).to eq('Smith')
    expect(contact.password_present).to eq(true)

    expect {
      contact.send_password_token_email
    }.to_not raise_error
  end

  describe 'merge_and_delete' do
    let(:contact) {
      Crm::Contact.create({
        language: 'en',
        last_name: 'Smith',
      })
    }
    let(:merge_into_contact) {
      Crm::Contact.create({
        language: 'en',
        last_name: 'Jones',
      })
    }

    it 'merges the contact into merge_into_contact and deletes it' do
      contact.merge_and_delete(merge_into_contact.id)
    end
  end

  describe 'first' do
    it 'returns the first contact' do
      contact = Crm::Contact.first
      expect(contact).to be_a(Crm::Contact)
      expect(contact.base_type).to eq('Contact')
      expect(contact.created_at).to be_present
    end
  end
end
