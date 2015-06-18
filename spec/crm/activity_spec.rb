require 'spec_helper'

module Crm

describe Activity do
  let(:item) { Activity.new({}) }

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
      Activity.new({
        'id' => 'abc',
        'title' => 'My Activity',
        'type_id' => 'form',
      })
    end

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(%|id="abc", title="My Activity", type_id="form">|)
    end
  end

  describe '#comments' do
    let(:updated_at) { "2014-11-10T10:58:43Z" }

    let(:activity) {
      Activity.new({
        'comments' => [{
          "attachments" => ["foo/bar.txt"],
          "updated_at" => updated_at,
          "updated_by" => "root",
          "notes" => "some note",
          "published" => true,
        }]
      })
    }

    it 'provides a list of comments' do
      comment = activity.comments.first

      expect(comment).to be_a Core::Mixins::AttributeProvider

      attachment = comment.attachments.first
      expect(attachment).to be_a(Activity::Comment::Attachment)
      expect(attachment.id).to eq('foo/bar.txt')
      expect(::Crm::Core::AttachmentStore).to receive(
          'generate_download_url').with('foo/bar.txt').and_return('the/download/url')
      expect(attachment.download_url).to eq('the/download/url')

      expect(comment.updated_at).to eq(Time.parse(updated_at))
      expect(comment.updated_at.zone).to eq('MSK')
      expect(comment.updated_at.hour).to eq(13)

      expect(comment.updated_by).to eq('root')
      expect(comment.notes).to eq('some note')
      expect(comment.published).to be(true)
      expect(comment).to be_published
    end

    it 'is also accessible via #attributes' do
      comment = activity.attributes[:comments].first

      expect(comment).to be_a Core::Mixins::AttributeProvider
      expect(comment).to be_a Activity::Comment
    end
  end
end

end
