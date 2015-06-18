require 'spec_helper'

module Crm

describe Collection do
  let(:item) { Collection.new({}) }
  let(:now) { Time.now.utc.xmlschema }

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
      Collection.new({
        'id' => 'abc',
        'title' => 'My Collection',
      })
    end

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(%|id="abc", title="My Collection">|)
    end
  end

  describe '#compute' do
    let(:collection) {
      Collection.new({
        'id' => '2342',
        'computation_started_at' => nil,
      })
    }

    it 'computes this collection' do
      expect(Core::RestApi.instance).to receive(:put).with('collections/2342/compute', {}).and_return({
        'id' => '2342',
        'computation_started_at' => now,
        'updated_at' => now,
      })
      expect(collection.compute).to be(collection)

      expect(collection.computation_started_at).to eq(now)
      expect(collection.updated_at).to eq(now)
    end
  end

  describe '#output_ids' do
    let(:collection) {
      Collection.new({
        'id' => '2342',
      })
    }

    it 'outputs the computed IDs of this collection' do
      expect(Core::RestApi.instance).to receive(:get).with('collections/2342/output_ids').
          and_return(['abc', 'def'])
      expect(collection.output_ids).to eq(['abc', 'def'])
    end
  end
end

end
