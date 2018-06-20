describe 'mailing recipient features' do
  let(:now) { Time.now.utc.xmlschema }

  describe 'find' do
    let(:mailing_recipient) do
      Crm::MailingRecipient.find(email)
    end
    let(:email) { "#{SecureRandom.hex(4)}@example.com" }

    it 'finds unsaved mailing recipients' do
      expect(mailing_recipient.id).to eq(email)
    end
  end

  describe 'update' do
    let(:mailing_recipient) do
      Crm::MailingRecipient.find(email)
    end
    let(:email) { "#{SecureRandom.hex(4)}@example.com" }

    it 'updates a mailing recipient under certain conditions', :aggregate_failures do
      # try to update mailing recipient with incomplete attributes
      expect {
        mailing_recipient.update({consent: 'revoked'})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors).to be_present
      end

      expect {
        mailing_recipient.update({does_not_exist: ''})
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # create mailing recipient
      mailing_recipient.update({consent: 'revoked', edit_reason: 'this is why'})
      expect(mailing_recipient.consent).to eq('revoked')
      logs = mailing_recipient.consent_logs
      expect(logs.size).to eq(1)
      expect(logs.first['at']).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
      expect(logs.first['description']).to eq("edited by API2 user root: this is why")
      expect(logs.first['changes']).to eq({"consent"=>[nil, "revoked"]})
      expect(mailing_recipient.version).to eq(1)

      # update mailing recipient
      mailing_recipient.update({consent: 'given', edit_reason: 'this is also why'})
      expect(mailing_recipient.consent).to eq('given')
      logs = mailing_recipient.consent_logs
      expect(logs.size).to eq(2)
      expect(logs.first['at']).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
      expect(logs.first['description']).to eq("edited by API2 user root: this is also why")
      expect(logs.first['changes']).to eq({"consent"=>["revoked", "given"]})
      expect(logs.last['at']).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
      expect(logs.last['description']).to eq("edited by API2 user root: this is why")
      expect(logs.last['changes']).to eq({"consent"=>[nil, "revoked"]})
      expect(mailing_recipient.version).to eq(2)
    end
  end
end
