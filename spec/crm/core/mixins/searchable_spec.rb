module Crm; module Core; module Mixins

describe Searchable do
  class MyResource < Crm::Core::BasicResource;
    include Searchable
  end

  describe '.first' do
    it 'searches for the first created item' do
      item = double(MyResource)
      item_enumerator = double(ItemEnumerator)

      expect(Crm).to receive(:search) do |options|
        expect(options[:filters]).to eq([{
          field: 'base_type',
          condition: 'equals',
          value: 'MyResource',
        }])
        expect(options[:limit]).to eq(1)
        expect(options[:sort_by]).to eq('created_at')

        item_enumerator
      end
      expect(item_enumerator).to receive(:first).and_return(item)

      expect(MyResource.first).to be(item)
    end

    context 'when there are no items' do
      it 'returns nil' do
        expect(Crm).to receive(:search).and_return(ItemEnumerator.new([], total: 0))

        expect(MyResource.first).to be_nil
      end
    end
  end

  describe '.all' do
    let(:item_ids) do
      (1..1001).map { |i| "abc#{i}" }
    end

    it 'returns an ItemEnumerator will all IDs of this base type (without deleted)' do
      expect(Crm).to receive(:search) do |options|
        expect(options[:filters]).to eq([{
          field: 'base_type',
          condition: 'equals',
          value: 'MyResource',
        }])
        expect(options[:limit]).to eq(:none)
        expect(options[:sort_by]).to eq('created_at')

        ItemEnumerator.new(item_ids, total: item_ids.length)
      end

      all_items = MyResource.all
      expect(all_items).to be_a(ItemEnumerator)
      expect(all_items.ids).to eq(item_ids)
    end

    context '.all(include_deleted: true)' do
      it 'includes IDs of deleted items' do
        expect(Crm).to receive(:search) do |named_parameter|
          expect(named_parameter[:include_deleted]).to be(true)
        end
        MyResource.all(include_deleted: true)
      end
    end

    context '.all(include_deleted: false)' do
      it 'includes IDs of deleted items' do
        expect(Crm).to receive(:search) do |named_parameter|
          expect(named_parameter[:include_deleted]).to be(false)
        end

        MyResource.all(include_deleted: false)
      end
    end
  end

  describe '.where' do
    it 'returns an SearchConfigurator with a filter preconfigured for this base type' do
      configurator = MyResource.where('last_name', 'equals', 'Smith')
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options[:filters]).to eq([
          {field: 'base_type', condition: 'equals', value: 'MyResource'},
          {field: 'last_name', condition: 'equals', value: 'Smith'},
        ])
      end

      configurator.perform_search
    end

    it 'can be called without a value' do
      configurator = MyResource.where('first_name', 'is_blank')
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options[:filters]).to eq([
          {field: 'base_type', condition: 'equals', value: 'MyResource'},
          {field: 'first_name', condition: 'is_blank', value: nil},
        ])
      end

      configurator.perform_search
    end
  end

  describe '.where_not' do
    it 'returns an SearchConfigurator with a negated filter preconfigured for this base type' do
      configurator = MyResource.where_not('last_name', 'equals', 'Smith')
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options[:filters]).to eq([
          {field: 'base_type', condition: 'equals', value: 'MyResource'},
          {field: 'last_name', condition: 'not_equals', value: 'Smith'},
        ])
      end

      configurator.perform_search
    end

    it 'can be called without a value' do
      configurator = MyResource.where_not('first_name', 'is_blank')
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options[:filters]).to eq([
          {field: 'base_type', condition: 'equals', value: 'MyResource'},
          {field: 'first_name', condition: 'not_is_blank', value: nil},
        ])
      end

      configurator.perform_search
    end
  end

  describe '.query' do
    it 'returns an SearchConfigurator with the given query preconfigured for this base type' do
      configurator = MyResource.query('my query')
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options[:query]).to eq('my query')
        expect(options[:filters]).to eq([
          {field: 'base_type', condition: 'equals', value: 'MyResource'}
        ])
      end

      configurator.perform_search
    end
  end

  describe '.search_configurator' do
    it 'returns an SearchConfigurator preconfigured for this base type' do
      configurator = MyResource.search_configurator
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options[:filters]).to eq([
          {field: 'base_type', condition: 'equals', value: 'MyResource'}
        ])
      end

      configurator.perform_search
    end
  end
end

end; end; end
