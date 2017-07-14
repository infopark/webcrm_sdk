module Crm

describe Contact do
  let(:item) { Contact.new({}) }

  it 'is a BasicResource' do
    expect(item).to be_a Core::BasicResource
  end

  it 'is Findable' do
    expect(item).to be_a Core::Mixins::Findable
  end

  it 'is Modifiable' do
    expect(item).to be_a Core::Mixins::Modifiable
  end

  it 'is ChangeLoggable' do
    expect(item).to be_a Core::Mixins::ChangeLoggable
  end

  it 'is MergeAndDeletable' do
    expect(item).to be_a Core::Mixins::MergeAndDeletable
  end

  it 'is Searchable' do
    expect(item).to be_a Core::Mixins::Searchable
  end

  describe '#inspect' do
    let(:item) do
      Contact.new({
        'id' => 'abc',
        'first_name' => 'John',
        'last_name' => 'Smith',
        'email' => 'john.smith@example.com',
      })
    end

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(
          %|id="abc", last_name="Smith", first_name="John", email="john.smith@example.com">|)
    end
  end

  describe '.authenticate!' do
    context 'with correct credentials' do
      it 'returns the authenticated contact' do
        expect(Core::RestApi.instance).to receive(:put).with(
          'contacts/authenticate', {'login' => 'user', 'password' => 'correct'}
        ).and_return({
          'login' => 'user',
          'last_name' => 'Smith',
        })

        contact = Contact.authenticate!('user', 'correct')
        expect(contact).to be_a Contact
        expect(contact.login).to eq('user')
        expect(contact.last_name).to eq('Smith')
      end
    end

    context 'with incorrect credentials' do
      it 'raises an error' do
        expect(Core::RestApi.instance).to receive(:put).and_raise(Errors::AuthenticationFailed)

        expect {
          Contact.authenticate!('user', 'wrong')
        }.to raise_error(Errors::AuthenticationFailed)
      end
    end
  end

  describe '.authenticate' do
    context 'with correct credentials' do
      let(:contact) { Contact.new({}) }

      it 'returns contact from authenticate!' do
        expect(Contact).to receive(:authenticate!).with('user', 'correct').and_return(contact)

        expect(Contact.authenticate('user', 'correct')).to be(contact)
      end
    end

    context 'with incorrect credentials' do
      it 'returns nil' do
        expect(Contact).to receive(:authenticate!).with('user', 'wrong').and_raise(
            Errors::AuthenticationFailed)
        expect(Contact.authenticate('user', 'wrong')).to be_nil
      end
    end
  end

  describe '#set_password' do
    let(:contact) { Contact.new({'id' => 'abc123', 'password_present' => false, 'version' => 1}) }

    it 'sets a new password for this contact' do
      expect(Core::RestApi.instance).to receive(:put).with(
        'contacts/abc123/set_password', {'password' => 'my new pw'}
      ).and_return({
        'id' => 'abc123',
        'password_present' => true,
        'version' => 2,
      })

      expect(contact.set_password('my new pw')).to be(contact)

      expect(contact.password_present).to be(true)
      expect(contact.version).to eq(2)
    end
  end

  describe '#clear_password' do
    let(:contact) { Contact.new({'id' => 'abc123', 'password_present' => true, 'version' => 1}) }

    it 'clears the password for this contact' do
      expect(Core::RestApi.instance).to receive(:put).with(
        'contacts/abc123/clear_password', {}
      ).and_return({
        'id' => 'abc123',
        'password_present' => false,
        'version' => 2,
      })

      expect(contact.clear_password).to be(contact)

      expect(contact.password_present).to be(false)
      expect(contact.version).to eq(2)
    end
  end

  describe '#generate_password_token' do
    let(:contact) { Contact.new({'id' => 'abc123'}) }

    it 'generates a token' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'contacts/abc123/generate_password_token', {}
      ).and_return({
        "token" => "xyz",
      })

      expect(contact.generate_password_token).to eq("xyz")
    end
  end

  describe '.set_password_by_token' do
    it 'set the new password for a contact identified by token' do
      expect(Core::RestApi.instance).to receive(:put).with(
        'contacts/set_password_by_token', {'password' => 'the password', 'token' => 'the token'}
      ).and_return({
        'id' => 'abc123',
        'password_present' => true,
        'version' => 2,
      })

      contact = Contact.set_password_by_token('the password', 'the token')
      expect(contact).to be_a Contact
      expect(contact.id).to eq('abc123')
      expect(contact.password_present).to be(true)
      expect(contact.version).to eq(2)
    end
  end

  describe '#send_password_token_email' do
    let(:contact) { Contact.new({'id' => 'abc123'}) }

    it 'sends an email' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'contacts/abc123/send_password_token_email', {}
      ).and_return({})

      contact.send_password_token_email
    end
  end
end

end
