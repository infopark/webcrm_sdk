describe 'mailing features' do
  before(:all) { CrmSetup.define_newsletter_mailing }
  let(:now) { Time.now.utc.xmlschema }
  let(:valid_sender) { 'support@infopark.de' }

  describe 'create' do
    it 'creates under certain conditions' do
      # try to create mailing with incomplete attributes
      expect {
        Crm::Mailing.create({})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      # create mailing
      mailing = Crm::Mailing.create({
        title: 'My Mailing',
        type_id: 'newsletter',
      })
      expect(mailing.id).to be_present
      expect(mailing.title).to eq('My Mailing')
      expect(mailing.type_id).to eq('newsletter')
    end
  end

  describe 'find' do
    let(:mailing) do
      Crm::Mailing.create({
        title: 'My Mailing',
        type_id: 'newsletter',
      })
    end

    it 'finds under certain conditions' do
      # find mailing with wrong ID fails with "ResourceNotFound"
      expect {
        Crm::Mailing.find('non-existing')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # find mailing
      expect(Crm::Mailing.find(mailing.id).title).to eq('My Mailing')
      expect(Crm::Mailing.find(mailing.id).id).to eq(mailing.id)
    end
  end

  describe 'update' do
    let(:mailing) do
      Crm::Mailing.create({
        title: 'My Mailing',
        type_id: 'newsletter',
      })
    end
    let!(:outdated_mailing) { Crm::Mailing.find(mailing.id) }

    it 'updates under certain conditions' do
      # try to update mailing with incomplete attributes
      expect {
        mailing.update(title: '')
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        mailing.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update mailing
      mailing.update(title: 'New Mailing Title')
      expect(mailing.title).to eq('New Mailing Title')
      expect(mailing.version).to eq(2)
      expect(Crm::Mailing.find(mailing.id).title).to eq('New Mailing Title')

      # optimistic locking for update
      expect{
        outdated_mailing.update(title: 'Something else')
      }.to raise_error(Crm::Errors::ResourceConflict)
    end
  end

  describe 'delete' do
    let(:mailing) do
      Crm::Mailing.create({
        title: 'My Mailing',
        type_id: 'newsletter',
      })
    end
    let!(:outdated_mailing) { Crm::Mailing.find(mailing.id) }

    before do
      mailing.update(title: 'just change something')
    end

    it 'deletes under certain conditions' do
      # optimistic locking for delete
      expect{
        outdated_mailing.delete
      }.to raise_error(Crm::Errors::ResourceConflict)
      mailing.delete
    end
  end

  describe 'changes' do
    let(:mailing) do
      Crm::Mailing.create({
        title: 'My Mailing',
        type_id: 'newsletter',
      })
    end

    before do
      mailing.update({title: 'My Mailing 2'})
    end

    it 'looks for changes' do
      changes = mailing.changes
      expect(changes.length).to eq(1)

      change = changes.detect do |change|
        change.details.has_key?('title')
      end
      expect(change.changed_at).to be_a(Time)
      expect(change.changed_by).to eq('root')

      detail = change.details['title']
      expect(detail.before).to eq('My Mailing')
      expect(detail.after).to eq('My Mailing 2')
    end
  end

  describe 'render preview' do
    let(:mailing) {
      Crm::Mailing.create({
        email_from: "Marketing <#{valid_sender}>",
        email_reply_to: 'marketing-replyto@example.com',
        email_subject: "Invitation to exhibition",
        html_body: '<h1>Welcome {{contact.first_name}} {{contact.last_name}}</h1>',
        text_body: 'Welcome {{contact.first_name}} {{contact.last_name}}',
        title: 'Preview this mailing',
        type_id: 'newsletter',
      })
    }
    let(:contact) {
      Crm::Contact.create({
        first_name: 'John',
        last_name: 'Doe',
        gender: 'M',
        language: 'en',
        email: 'success@simulator.amazonses.com',
      })
    }

    it 'renders the correct preview' do
      expect(mailing.render_preview(contact.id)).to eq({
        "email_from" => "Marketing <support@infopark.de>",
        "email_reply_to" => "marketing-replyto@example.com",
        "email_subject" => "Invitation to exhibition",
        "email_to" => "success@simulator.amazonses.com",
        "html_body" => "<h1>Welcome John Doe</h1>",
        "text_body" => "Welcome John Doe",
      })
    end

    it 'handles errors correctly' do
      expect {
        mailing.render_preview('non-existing-contact-id')
      }.to raise_error(Crm::Errors::InvalidValues)
      expect {
        mailing.render_preview(nil)
      }.to raise_error(Crm::Errors::InvalidValues)
    end
  end

  describe 'send_me_a_proof_email' do
    before do
      CrmSetup.set_api_user_email
    end

    let(:mailing) {
      Crm::Mailing.create({
        email_from: "Marketing <#{valid_sender}>",
        title: 'Proof send this mailing',
        type_id: 'newsletter',
      })
    }
    let(:contact) {
      Crm::Contact.create({
        last_name: 'Doe',
        gender: 'M',
        language: 'en',
      })
    }

    it 'sends a proof email to me (the api user)' do
      expect(mailing.send_me_a_proof_email(contact.id)).to eq(
          {"message" => "email sent to success@simulator.amazonses.com"})
    end

    it 'handles errors correctly' do
      expect {
        mailing.send_me_a_proof_email('non-existing-contact-id')
      }.to raise_error(Crm::Errors::InvalidValues)
      expect {
        mailing.send_me_a_proof_email(nil)
      }.to raise_error(Crm::Errors::InvalidValues)
    end
  end

  describe 'send_single_email' do
    let(:mailing) {
      Crm::Mailing.create({
        email_from: "Marketing <#{valid_sender}>",
        title: 'Mailing, that should be send_single_email',
        type_id: 'newsletter',
      })
    }
    let(:contact) {
      Crm::Contact.create({
        last_name: 'Doe',
        gender: 'M',
        language: 'en',
        email: 'success@simulator.amazonses.com',
      })
    }

    it 'sends a single email' do
      mailing.release
      expect(mailing.send_single_email(contact.id)).to eq(
          {"message" => "email sent to success@simulator.amazonses.com"})
    end

    it 'handles errors correctly' do
      expect {
        mailing.send_single_email(contact.id)
      }.to raise_error(Crm::Errors::ItemStatePreconditionFailed) do |error|
        expect(error.unmet_preconditions).to eq(
            [{"code" => "released", "message" => "The mailing is not released."}])
      end

      mailing.release

      expect {
        mailing.send_single_email('non-existing-contact-id')
      }.to raise_error(Crm::Errors::InvalidValues)
      expect {
        mailing.send_single_email(nil)
      }.to raise_error(Crm::Errors::InvalidValues)
    end
  end

  describe 'release' do
    let(:collection) {
      Crm::Collection.create({
        title: 'My Mailing Collection',
        collection_type: 'contact',
        filters: [[{
          field: 'contact.id',
          condition: 'is_one_of',
          value: []
        }]]
      })
    }
    let(:mailing) {
      Crm::Mailing.create({
        collection_id: collection.id,
        email_from: "Marketing <#{valid_sender}>",
        title: 'Release Party',
        type_id: 'newsletter',
      })
    }

    it 'releases the mailing' do
      expect(mailing.released_at).to_not be_present
      expect(mailing.released_by).to_not be_present

      mailing.release

      expect(mailing.released_at).to be_present
      expect(mailing.released_by).to eq('root')
    end

    it 'handles errors correctly' do
      mailing.delete

      expect {
        mailing.release
      }.to raise_error(Crm::Errors::ResourceNotFound)
    end
  end

  describe 'first' do
    it 'returns the first mailing' do
      mailing = Crm::Mailing.first
      expect(mailing).to be_a(Crm::Mailing)
      expect(mailing.base_type).to eq('Mailing')
      expect(mailing.created_at).to be_present
    end
  end
end
