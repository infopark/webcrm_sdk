describe 'mailing delivery features' do
  before(:all) { CrmSetup.define_newsletter_mailing }

  describe 'everything' do
    it 'works' do
      mailing = Crm::Mailing.create({
        title: 'My Mailing',
        type_id: 'newsletter',
      })

      expect(Crm::MailingDelivery.all(mailing.id)).to eq([])

      expect {
        Crm::MailingDelivery.find('non-existing', 'john.doe@example.com')
      }.to raise_error(Crm::Errors::ResourceNotFound)
      expect {
        Crm::MailingDelivery.find(mailing.id, 'john.doe@example.com')
      }.to raise_error(Crm::Errors::ResourceNotFound)

      # add a mailing delivery
      md = Crm::MailingDelivery.create(mailing.id, 'john.doe@example.com', {})
      expect(md.id).to eq('john.doe@example.com')

      mds = Crm::MailingDelivery.all(mailing.id)
      expect(mds.size).to eq(1)
      expect(mds.first.id).to eq('john.doe@example.com')

      expect(Crm::MailingDelivery.all(mailing.id, since: 1.minute.from_now)).to eq([])
      expect(Crm::MailingDelivery.all(mailing.id, since: 1.minute.from_now.utc.xmlschema)).to eq([])
      expect {
        Crm::MailingDelivery.all(mailing.id, since: true)
      }.to raise_error('unknown class of since param: TrueClass')

      md = Crm::MailingDelivery.find(mailing.id, 'john.doe@example.com')
      expect(md.id).to eq('john.doe@example.com')
      expect(md.custom_data).to eq({})

      # update a mailing delivery (by creating again)
      md = Crm::MailingDelivery.create(mailing.id, 'john.doe@example.com', {
        'custom_data' => {'salutation' => 'Hello John'}},
      )
      expect(md.id).to eq('john.doe@example.com')
      expect(md.custom_data).to eq({'salutation' => 'Hello John'})

      # update a mailing delivery
      md.update({'custom_data' => {'salutation' => 'Hello You'}})
      expect(md.custom_data).to eq({'salutation' => 'Hello You'})

      md = Crm::MailingDelivery.find(mailing.id, 'john.doe@example.com')
      expect(md.id).to eq('john.doe@example.com')
      expect(md.custom_data).to eq({'salutation' => 'Hello You'})

      # delete
      md.delete
      expect {
        Crm::MailingDelivery.find(mailing.id, 'john.doe@example.com')
      }.to raise_error(Crm::Errors::ResourceNotFound)
    end
  end
end
