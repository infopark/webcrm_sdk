module Crm; module Core

describe SearchConfigurator do
  describe '#perform_search' do
    context 'without any options' do
      it 'performs a search with default parameters' do
        expect(Crm).to receive(:search) do |options|
          expect(options.delete(:filters)).to eq([])
          expect(options.delete(:query)).to be_nil
          expect(options.delete(:limit)).to be_nil
          expect(options.delete(:offset)).to be_nil
          expect(options.delete(:sort_by)).to be_nil
          expect(options.delete(:sort_order)).to be_nil

          expect(options).to eq({})

          ItemEnumerator.new(['a', 'b', 'c'])
        end

        items = SearchConfigurator.new.perform_search
        expect(items).to be_a(ItemEnumerator)
        expect(items.ids).to eq(['a', 'b', 'c'])
      end
    end

    it 'caches the result' do
      configurator = SearchConfigurator.new.limit(10)
      expect(configurator.perform_search).to be(configurator.perform_search)
    end
  end

  let(:initial_configurator) do
    SearchConfigurator.new({
      filters: [{field: :title, condition: 'equals', value: 'welcome'}],
      query: 'initial query',
      limit: 8,
      offset: 17,
      sort_by: 'title',
      sort_order: 'asc',
    })
  end

  [:and, :add_filter].each do |method_name|
    describe "##{method_name}" do
      it 'adds a filter, and keeps everything else' do
        configurator = initial_configurator.public_send(method_name, :last_name, :equals, 'Smith')
        expect(configurator).to be_a(SearchConfigurator)

        expect(Crm).to receive(:search) do |options|
          expect(options.delete(:filters)).to eq([
            {field: :title, condition: 'equals', value: 'welcome'},
            {field: :last_name, condition: :equals, value: 'Smith'},
          ])
          expect(options.delete(:query)).to eq('initial query')
          expect(options.delete(:limit)).to eq(8)
          expect(options.delete(:offset)).to eq(17)
          expect(options.delete(:sort_by)).to eq('title')
          expect(options.delete(:sort_order)).to eq('asc')

          expect(options).to eq({})
        end

        configurator.perform_search
      end
    end

    it 'can be called without a value' do
      configurator = initial_configurator.public_send(method_name, :first_name, :is_blank)
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options[:filters]).to eq([
          {field: :title, condition: 'equals', value: 'welcome'},
          {field: :first_name, condition: :is_blank, value: nil},
        ])
      end

      configurator.perform_search
    end
  end

  [:and_not, :add_negated_filter].each do |method_name|
    describe "##{method_name}" do
      it 'adds a filter, and keeps everything else' do
        configurator = initial_configurator.public_send(method_name, :last_name, :equals, 'Smith')
        expect(configurator).to be_a(SearchConfigurator)

        expect(Crm).to receive(:search) do |options|
          expect(options.delete(:filters)).to eq([
            {field: :title, condition: 'equals', value: 'welcome'},
            {field: :last_name, condition: 'not_equals', value: 'Smith'},
          ])
          expect(options.delete(:query)).to eq('initial query')
          expect(options.delete(:limit)).to eq(8)
          expect(options.delete(:offset)).to eq(17)
          expect(options.delete(:sort_by)).to eq('title')
          expect(options.delete(:sort_order)).to eq('asc')

          expect(options).to eq({})
        end

        configurator.perform_search
      end

      it 'can be called without a value' do
        configurator = initial_configurator.public_send(method_name, :first_name, :is_blank)
        expect(configurator).to be_a(SearchConfigurator)

        expect(Crm).to receive(:search) do |options|
          expect(options[:filters]).to eq([
            {field: :title, condition: 'equals', value: 'welcome'},
            {field: :first_name, condition: 'not_is_blank', value: nil},
          ])
        end

        configurator.perform_search
      end
    end
  end

  describe '#query' do
    it 'changes query, and keeps everything else' do
      configurator = initial_configurator.query('my new query')
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options.delete(:filters)).to eq([{field: :title, condition: 'equals', value: 'welcome'}],)
        expect(options.delete(:query)).to eq('my new query')
        expect(options.delete(:limit)).to eq(8)
        expect(options.delete(:offset)).to eq(17)
        expect(options.delete(:sort_by)).to eq('title')
        expect(options.delete(:sort_order)).to eq('asc')

        expect(options).to eq({})
      end

      configurator.perform_search
    end
  end

  describe '#limit' do
    it 'changes the limit, and keeps everything else' do
      configurator = initial_configurator.limit(23)
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options.delete(:filters)).to eq([{field: :title, condition: 'equals', value: 'welcome'}],)
        expect(options.delete(:query)).to eq('initial query')
        expect(options.delete(:limit)).to eq(23)
        expect(options.delete(:offset)).to eq(17)
        expect(options.delete(:sort_by)).to eq('title')
        expect(options.delete(:sort_order)).to eq('asc')

        expect(options).to eq({})
      end

      configurator.perform_search
    end
  end

  describe '#unlimited' do
    it 'changes the limit to :none, and keeps everything else' do
      configurator = initial_configurator.unlimited
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options.delete(:filters)).to eq([{field: :title, condition: 'equals', value: 'welcome'}],)
        expect(options.delete(:query)).to eq('initial query')
        expect(options.delete(:limit)).to eq(:none)
        expect(options.delete(:offset)).to eq(17)
        expect(options.delete(:sort_by)).to eq('title')
        expect(options.delete(:sort_order)).to eq('asc')

        expect(options).to eq({})
      end

      configurator.perform_search
    end
  end

  describe '#offset' do
    it 'changes the offset, and keeps everything else' do
      configurator = initial_configurator.offset(23)
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options.delete(:filters)).to eq([{field: :title, condition: 'equals', value: 'welcome'}],)
        expect(options.delete(:query)).to eq('initial query')
        expect(options.delete(:limit)).to eq(8)
        expect(options.delete(:offset)).to eq(23)
        expect(options.delete(:sort_by)).to eq('title')
        expect(options.delete(:sort_order)).to eq('asc')

        expect(options).to eq({})
      end

      configurator.perform_search
    end
  end

  describe '#sort_by' do
    it 'changes the sort_by, and keeps everything else' do
      configurator = initial_configurator.sort_by('created_at')
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options.delete(:filters)).to eq([{field: :title, condition: 'equals', value: 'welcome'}],)
        expect(options.delete(:query)).to eq('initial query')
        expect(options.delete(:limit)).to eq(8)
        expect(options.delete(:offset)).to eq(17)
        expect(options.delete(:sort_by)).to eq('created_at')
        expect(options.delete(:sort_order)).to eq('asc')

        expect(options).to eq({})
      end

      configurator.perform_search
    end
  end

  describe '#sort_order' do
    it 'changes the sort_by, and keeps everything else' do
      configurator = initial_configurator.sort_order('desc')
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options.delete(:filters)).to eq([{field: :title, condition: 'equals', value: 'welcome'}],)
        expect(options.delete(:query)).to eq('initial query')
        expect(options.delete(:limit)).to eq(8)
        expect(options.delete(:offset)).to eq(17)
        expect(options.delete(:sort_by)).to eq('title')
        expect(options.delete(:sort_order)).to eq('desc')

        expect(options).to eq({})
      end

      configurator.perform_search
    end
  end

  describe '#desc' do
    it 'changes the sort_order to desc, and keeps everything else' do
      configurator = initial_configurator.desc
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options.delete(:filters)).to eq([{field: :title, condition: 'equals', value: 'welcome'}],)
        expect(options.delete(:query)).to eq('initial query')
        expect(options.delete(:limit)).to eq(8)
        expect(options.delete(:offset)).to eq(17)
        expect(options.delete(:sort_by)).to eq('title')
        expect(options.delete(:sort_order)).to eq('desc')

        expect(options).to eq({})
      end

      configurator.perform_search
    end
  end

  describe '#asc' do
    let(:initial_configurator) do
      SearchConfigurator.new({
        filters: [{field: :title, condition: 'equals', value: 'welcome'}],
        query: 'initial query',
        limit: 8,
        offset: 17,
        sort_by: 'title',
        sort_order: 'desc',
      })
    end

    it 'changes the sort_order to asc, and keeps everything else' do
      configurator = initial_configurator.asc
      expect(configurator).to be_a(SearchConfigurator)

      expect(Crm).to receive(:search) do |options|
        expect(options.delete(:filters)).to eq([{field: :title, condition: 'equals', value: 'welcome'}],)
        expect(options.delete(:query)).to eq('initial query')
        expect(options.delete(:limit)).to eq(8)
        expect(options.delete(:offset)).to eq(17)
        expect(options.delete(:sort_by)).to eq('title')
        expect(options.delete(:sort_order)).to eq('asc')

        expect(options).to eq({})
      end

      configurator.perform_search
    end
  end

  describe 'Enumerable' do
    let(:configurator) { SearchConfigurator.new }
    let(:item_enumerator) { ItemEnumerator.new(['abc', 'def'], total: 20) }
    let(:contact_abc) { Contact.new({'id' => 'abc'}) }
    let(:contact_def) { Contact.new({'id' => 'def'}) }

    it 'is an Enumerable' do
      expect(configurator).to be_a Enumerable
    end

    describe '#each' do
      context 'with a block' do
        it 'yields results of #perform_search.each' do
          expect(configurator).to receive(:perform_search).and_return(item_enumerator)
          expect(item_enumerator).to receive(:each).and_yield(contact_abc).and_yield(contact_def)

          expected_items = [contact_abc, contact_def]
          configurator.each do |item|
            expect(item).to eq(expected_items.shift)
          end
          expect(expected_items).to be_empty
        end
      end

      context 'as an iterator' do
        it 'iterates over results of #perform_search.each' do
          expect(configurator).to receive(:perform_search).and_return(item_enumerator)
          expect(item_enumerator).to receive(:each).and_yield(contact_abc).and_yield(contact_def)

          iterator = configurator.each
          expect(iterator.next).to eq(contact_abc)
          expect(iterator.next).to eq(contact_def)
          expect { iterator.next }.to raise_error(StopIteration)
        end
      end
    end

    describe '#take(n)' do
      it 'limits the number of search results to n and executes the search' do
        expect(Crm).to receive(:search) do |args|
          expect(args[:limit]).to eq(2)

          item_enumerator
        end
        expect(item_enumerator).to receive(:each).and_yield(contact_abc).and_yield(contact_def)

        expect(configurator.take(2)).to eq([contact_abc, contact_def])
      end
    end

    describe 'first' do
      context 'with an empty result set' do
        it 'returns nil' do
          expect(Crm).to receive(:search).and_return(ItemEnumerator.new([], total: 0))

          expect(configurator.first).to be_nil
        end
      end

      context 'with a non-empty result set' do
        it 'limits the number of search results to 1 and returns the first item' do
          expect(Crm).to receive(:search) do |args|
            expect(args[:limit]).to eq(1)

            item_enumerator
          end
          expect(item_enumerator).to receive(:each).and_yield(contact_abc)

          expect(configurator.first).to eq(contact_abc)
        end
      end
    end

    describe 'first(n)' do
      it 'delegates to take(n)' do
        expect(configurator).to receive(:take).with(2)

        configurator.first(2)
      end
    end

    describe '#total' do
      it 'returns #perform_search.total' do
        expect(configurator).to receive(:perform_search).and_return(item_enumerator)

        expect(configurator.total).to eq(20)
      end
    end
  end
end

end; end
