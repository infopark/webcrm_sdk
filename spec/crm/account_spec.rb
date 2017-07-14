module Crm

describe Account do
  let(:item) { Account.new({}) }

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
      Account.new({
        'id' => 'abc',
        'name' => 'Company Inc.',
      })
    end

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(%|id="abc", name="Company Inc.">|)
    end
  end
end

end
