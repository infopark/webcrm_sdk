require 'spec_helper'

module Crm

describe Mailing do
  let(:item) { Mailing.new({}) }

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

  it 'is Searchable' do
    expect(item).to be_a Core::Mixins::Searchable
  end

  describe '#inspect' do
    let(:item) do
      Mailing.new({
        'id' => 'abc',
        'title' => 'My Mailing',
      })
    end

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(%|id="abc", title="My Mailing">|)
    end
  end

  describe '#render_preview' do
    let(:mailing) { Mailing.new("id" => "abc") }
    let(:preview_output) {
      {
        'email_subject' => "Invitation to exhibition",
        'text_body' => "Welcome Mr. John Doe...",
      }
    }

    before do
      expect(Core::RestApi.instance).to receive(:post).with(
        'mailings/abc/render_preview', {'render_for_contact_id' => '2342'}
      ).and_return(preview_output)
    end

    it 'renders a preview for the given contact ID' do
      expect(mailing.render_preview('2342')).to eq(preview_output)
    end

    it 'renders a preview for the given contact' do
      contact = Contact.new("id" => "2342")
      expect(mailing.render_preview(contact)).to eq(preview_output)
    end
  end

  describe '#send_me_a_proof_email' do
    let(:mailing) { Mailing.new("id" => "abc") }
    let(:proof_output) { { "message" => "e-mail sent to apiuser.email" } }

    before do
      expect(Core::RestApi.instance).to receive(:post).with(
        'mailings/abc/send_me_a_proof_email', {'render_for_contact_id' => '2342'}
      ).and_return(proof_output)
    end

    it 'sends a proof email to me, rendered using the given contact id' do
      expect(mailing.send_me_a_proof_email('2342')).to eq(proof_output)
    end

    it 'sends a proof email to me, rendered using the given contact' do
      contact = Contact.new("id" => "2342")
      expect(mailing.send_me_a_proof_email(contact)).to eq(proof_output)
    end
  end

  describe '#release' do
    let(:mailing) { Mailing.new("id" => "abc") }
    let(:now) { Time.now.utc.xmlschema }

    it 'releases the mailing' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'mailings/abc/release', {}
      ).and_return({
        "id" => "abc",
        "released_at" => now,
      })

      expect(mailing.release).to be(mailing)
      expect(mailing.id).to eq('abc')
      expect(mailing.released_at).to eq(now)
    end
  end

  describe '#send_single_email' do
    let(:mailing) { Mailing.new("id" => "abc") }
    let(:single_email_output) { { "message" => "e-mail sent to contact.email" } }

    before do
      expect(Core::RestApi.instance).to receive(:post).with(
        'mailings/abc/send_single_email', {'recipient_contact_id' => '2342'}
      ).and_return(single_email_output)
    end

    it 'sends a single email to the given contact ID' do
      expect(mailing.send_single_email('2342')).to eq(single_email_output)
    end

    it 'sends a single email to the given contact' do
      contact = Contact.new("id" => "2342")
      expect(mailing.send_single_email(contact)).to eq(single_email_output)
    end
  end
end

end
