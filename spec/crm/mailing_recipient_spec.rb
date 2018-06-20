module Crm

describe MailingRecipient do
  let(:item) { MailingRecipient.new({}) }

  it 'is a BasicResource' do
    expect(item).to be_a Core::BasicResource
  end

  describe '#inspect' do
    let(:item) do
      MailingRecipient.new({
        'active' => true,
        'consent' => 'unknown',
        'id' => 'abc@example.com',
        'topic_names' => ['abc', 'def'],
      })
    end

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(
          "id=\"abc@example.com\", active=true, consent=\"unknown\", topic_names=[\"abc\", \"def\"]")
    end
  end

  describe '#update' do
    let(:resource) {
      MailingRecipient.new({
        'id' => 'abc@example.com',
        'active' => true,
        'consent' => 'revoked',
        'version' => 2,
      })
    }
    let(:now) { Time.now.utc.xmlschema }

    it 'updates the resource' do
      expect(Core::RestApi.instance).to receive(:put).with(
        'mailing_recipients/abc@example.com', {'consent' => 'given'}, {'If-Match' => 2}
      ).and_return({
        'id' => 'abc@example.com',
        'active' => true,
        'consent' => 'given',
        'updated_at' => now,
      })
      expect(resource.update({'consent' => 'given'})).to be(resource)

      expect(resource.active).to eq(true)
      expect(resource.consent).to eq('given')
      expect(resource.updated_at).to eq(now)
    end
  end
end

end
