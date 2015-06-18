require 'spec_helper'

module Crm

describe Type do
  let(:item) { Type.new({}) }

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

  describe '#inspect' do
    let(:item) do
      Type.new({
        'id' => 'abc',
        'item_base_type' => 'Activity',
      })
    end

    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(%|id="abc", item_base_type="Activity">|)
    end
  end

  describe '.all' do
    it 'returns all types (without deleted)' do
      expect(Core::RestApi.instance).to receive(:get).with(
          'types', {include_deleted: false}).and_return([
        {
          "id" => "mailing",
          "item_base_type" => "Mailing",
          "base_type" => "Type",
        },
        {
          "id" => "support-case",
          "item_base_type" => "Activity",
          "base_type" => "Type",
        },
      ])
      result = Type.all
      expect(result.map(&:id)).to eq(["mailing", "support-case"])
      expect(result.map(&:item_base_type)).to eq(["Mailing", "Activity"])
      expect(result).to all( be_a(::Crm::Type) )
    end

    context '.all(include_deleted: true)' do
      it 'returns all types with deleted' do
        expect(Core::RestApi.instance).to receive(:get).with(
            'types', {include_deleted: true}).and_return([])
        Type.all(include_deleted: true)
      end
    end

    context '.all(include_deleted: false)' do
      it 'returns all types with deleted' do
        expect(Core::RestApi.instance).to receive(:get).with(
            'types', {include_deleted: false}).and_return([])
        Type.all(include_deleted: false)
      end
    end
  end
end

end
