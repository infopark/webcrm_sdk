module Crm

describe '.search' do
  let(:search_result_items) do
    item_ids.map do |item_id|
      {"id" => item_id, "base_type" => "MyResource"}
    end
  end

  context 'without optional parameters' do
    let(:item_ids) do
      (1..10).map { |i| "abc#{i}" }
    end

    it 'searches with server defaults' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'search', {
          'limit' => 100,
          'offset' => 0,
        }
      ).and_return({
        'results' => search_result_items,
        'total' => 10,
      })

      item_enum = Crm.search
      expect(item_enum).to be_a(Core::ItemEnumerator)
      expect(item_enum.ids).to eq(item_ids)
      expect(item_enum.total).to eq(10)
    end
  end

  context 'with filters' do
    let(:item_ids) do
      (1..10).map { |i| "abc#{i}" }
    end

    it 'searches with the given filters' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'search', {
          'filters' => ['my_filter'],
          'limit' => 100,
          'offset' => 0,
        }
      ).and_return({
        'results' => search_result_items,
        'total' => 10,
      })

      item_enum = Crm.search(filters: ['my_filter'])
      expect(item_enum).to be_a(Core::ItemEnumerator)
      expect(item_enum.ids).to eq(item_ids)
      expect(item_enum.total).to eq(10)
    end
  end

  context 'with query' do
    let(:item_ids) do
      (1..10).map { |i| "abc#{i}" }
    end

    it 'searches with the given query' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'search', {
          'query' => 'my query',
          'limit' => 100,
          'offset' => 0,
        }
      ).and_return({
        'results' => search_result_items,
        'total' => 10,
      })

      item_enum = Crm.search(query: 'my query')
      expect(item_enum).to be_a(Core::ItemEnumerator)
      expect(item_enum.ids).to eq(item_ids)
      expect(item_enum.total).to eq(10)
    end
  end

  context 'with limit' do
    let(:item_ids) do
      (1..102).map { |i| "abc#{i}" }
    end

    context 'when limit > total' do
      it 'returns total many items' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 10,
            'offset' => 0,
          }
        ).and_return({
          'results' => search_result_items.take(8),
          'total' => 8,
        })

        item_enum = Crm.search(limit: 10)
        expect(item_enum).to be_a(Core::ItemEnumerator)
        expect(item_enum.ids).to eq(item_ids.take(8))
        expect(item_enum.total).to eq(8)
      end
    end

    context 'when limit < 100' do
      it 'searches for the given limit' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 99,
            'offset' => 0,
          }
        ).and_return({
          'results' => search_result_items.take(99),
          'total' => 102,
        })

        item_enum = Crm.search(limit: 99)
        expect(item_enum).to be_a(Core::ItemEnumerator)
        expect(item_enum.ids).to eq(item_ids.take(99))
        expect(item_enum.total).to eq(102)
      end
    end

    context 'when limit == 100' do
      it 'searches for the given limit' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 100,
            'offset' => 0,
          }
        ).and_return({
          'results' => search_result_items.take(100),
          'total' => 102,
        })

        item_enum = Crm.search(limit: 100)
        expect(item_enum).to be_a(Core::ItemEnumerator)
        expect(item_enum.ids).to eq(item_ids.take(100))
        expect(item_enum.total).to eq(102)
      end
    end

    context 'when limit > 100' do
      it 'searches multiple times for the given limit' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 100,
            'offset' => 0,
          }
        ).and_return({
          'results' => search_result_items.take(100),
          'total' => 102,
        })

        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 1,
            'offset' => 100,
          }
        ).and_return({
          'results' => [search_result_items[100]],
          'total' => 102,
        })

        item_enum = Crm.search(limit: 101)
        expect(item_enum).to be_a(Core::ItemEnumerator)
        expect(item_enum.ids).to eq(item_ids.take(101))
        expect(item_enum.total).to eq(102)
      end
    end

    context 'when limit == :none' do
      it 'searches multiple times for all items' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 100,
            'offset' => 0,
          }
        ).and_return({
          'results' => search_result_items.take(100),
          'total' => 102,
        })

        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 100,
            'offset' => 100,
          }
        ).and_return({
          'results' => search_result_items.last(2),
          'total' => 102,
        })

        item_enum = Crm.search(limit: :none)
        expect(item_enum).to be_a(Core::ItemEnumerator)
        expect(item_enum.ids).to eq(item_ids)
        expect(item_enum.total).to eq(102)
      end
    end

    context 'when limit == nil' do
      it 'searches with default limit (:none)' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 100,
            'offset' => 0,
          }
        ).and_return({
          'results' => search_result_items.take(10),
          'total' => 10,
        })

        item_enum = Crm.search(limit: nil)
        expect(item_enum).to be_a(Core::ItemEnumerator)
        expect(item_enum.ids).to eq(item_ids.take(10))
        expect(item_enum.total).to eq(10)
      end
    end
  end

  context 'with offset' do
    let(:item_ids) do
      (1..105).map { |i| "abc#{i}" }
    end

    it 'searches with that offset' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'search', {
          'limit' => 100,
          'offset' => 2,
        }
      ).and_return({
        'results' => search_result_items[2, 100],
        'total' => 105,
      })

      expect(Core::RestApi.instance).to receive(:post).with(
        'search', {
          'limit' => 100,
          'offset' => 102,
        }
      ).and_return({
        'results' => search_result_items[102, 3],
        'total' => 105,
      })

      item_enum = Crm.search(offset: 2, limit: :none)
      expect(item_enum).to be_a(Core::ItemEnumerator)
      expect(item_enum.ids).to eq(item_ids[2..-1])
      expect(item_enum.total).to eq(105)
    end

    context 'with limit > 100, but limit < total' do
      let(:item_ids) do
        (1..240).map { |i| "abc#{i}" }
      end

      it 'searches for limit many items using the given offset' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 100,
            'offset' => 99,
          }
        ).and_return({
          'results' => search_result_items[99, 100],
          'total' => 240,
        })

        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 10,
            'offset' => 199,
          }
        ).and_return({
          'results' => search_result_items[199, 10],
          'total' => 240,
        })

        item_enum = Crm.search(offset: 99, limit: 110)
        expect(item_enum).to be_a(Core::ItemEnumerator)
        expect(item_enum.ids).to eq(item_ids[99, 110])
        expect(item_enum.total).to eq(240)
      end
    end

    context 'with offset == nil' do
      it 'searches with default offset' do
        expect(Core::RestApi.instance).to receive(:post).with(
          'search', {
            'limit' => 100,
            'offset' => 0,
          }
        ).and_return({
          'results' => search_result_items.take(10),
          'total' => 10,
        })

        item_enum = Crm.search(offset: nil)
        expect(item_enum).to be_a(Core::ItemEnumerator)
        expect(item_enum.ids).to eq(item_ids.take(10))
        expect(item_enum.total).to eq(10)
      end
    end
  end

  context 'with sort_by and sort_order' do
    let(:item_ids) do
      (1..10).map { |i| "abc#{i}" }
    end

    it 'searches using the given sort' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'search', {
          'limit' => 100,
          'offset' => 0,
          'sort_by' => 'my_sort',
          'sort_order' => 'my_order',
        }
      ).and_return({
        'results' => search_result_items,
        'total' => 10,
      })

      item_enum = Crm.search(sort_by: 'my_sort', sort_order: 'my_order')
      expect(item_enum).to be_a(Core::ItemEnumerator)
      expect(item_enum.ids).to eq(item_ids)
      expect(item_enum.total).to eq(10)
    end
  end

  context 'with include_deleted = true' do
    let(:item_ids) do
      (1..10).map { |i| "abc#{i}" }
    end

    it 'searches with deleted included' do
      expect(Core::RestApi.instance).to receive(:post).with(
        'search', {
          'limit' => 100,
          'offset' => 0,
          'include_deleted' => true,
        }
      ).and_return({
        'results' => search_result_items,
        'total' => 10,
      })

      item_enum = Crm.search(include_deleted: true)
      expect(item_enum).to be_a(Core::ItemEnumerator)
      expect(item_enum.ids).to eq(item_ids)
      expect(item_enum.total).to eq(10)
    end
  end
end

end
