require 'spec_helper'

module Crm

describe Event do
  let(:item) { Event.new({}) }

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
      Event.new({
        'id' => 'abc',
        'title' => 'My Event',
      })
    end

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(%|id="abc", title="My Event">|)
    end
  end
end

end
