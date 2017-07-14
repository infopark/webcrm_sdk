module Crm; module Core; module Mixins

describe AttributeProvider do
  class MyItem;
    include AttributeProvider

    def update_attributes(attrs)
      load_attributes(attrs)
    end
  end

  describe '#initialize' do
    context 'with no arguments given' do
      let(:item) { MyItem.new }

      it 'returns nil/undefined method exception for unknown keys' do
        expect(item['unknown_key']).to be_nil
        expect(item[:unknown_key]).to be_nil
        expect { item.unknown_key }.to raise_error(NoMethodError)
      end

      it 'returns an empty hash for #attributes' do
        expect(item.attributes).to eq({})
      end
    end

    context 'with arguments given' do
      let(:item) { MyItem.new({'foo' => 'bar'}) }

      it 'makes the given arguments accessible' do
        expect(item['foo']).to eq('bar')
        expect(item[:foo]).to eq('bar')
        expect(item.foo).to eq('bar')

        expect(item.attributes).to eq({'foo' => 'bar'})
        expect(item.attributes['foo']).to eq('bar')
        expect(item.attributes[:foo]).to eq('bar')
      end
    end
  end

  describe 'protected #load_attributes' do
    let(:item) { MyItem.new }
    let(:now) { '2014-11-10T10:34:00Z' }

    before do
      item.update_attributes({
        'foo' => 'bar',
        'blub' => 2342,
        'bla' => nil,
        'started_at' => now,
        'deleted_at' => nil,
        'my_hash' => {'abc' => 'xyz'},
        'located_at' => 'This is not a date, but ends with _at',
      })
    end

    it 'makes given args available as methods and via #[]' do
      [
        [:foo, 'bar'],
        [:blub, 2342],
        [:bla, nil],
        [:started_at, Time.parse(now)],
        [:deleted_at, nil],
        [:my_hash, {'abc' => 'xyz'}],
        [:located_at, nil],
      ].each do |key, expected_value|
        expect(item.public_send(key)).to eq(expected_value)
        expect(item[key]).to eq(expected_value)
        expect(item[key.to_s]).to eq(expected_value)

        expect(item.attributes[key]).to eq(expected_value)
        expect(item.attributes[key.to_s]).to eq(expected_value)
      end
    end

    it 'converts timestamps into local timezone' do
      expect(item.started_at.zone).to eq('MSK')
      expect(item.started_at.hour).to eq(13)
    end

    it 'enabled accessing keys with string or symbol' do
      expect(item.my_hash['abc']).to eq('xyz')
      expect(item.my_hash[:abc]).to eq('xyz')
    end

    it 'raises a MethodNotFound, when the method in args is not given' do
      expect{ item.bar }.to raise_error(NoMethodError)
    end

    describe '#[]' do
      it 'returns nil, when key does not exist' do
        expect(item['random_key']).to eq(nil)
        expect(item[:random_key]).to eq(nil)
      end
    end

    describe '#attributes' do
      context 'when modifying the result of #attributes' do
        it 'refuses to modify the hash' do
          expect {
            item.attributes['foo'] = 'changed'
          }.to raise_error(/can't modify frozen/)

          expect(item.foo).to eq('bar')
        end
      end
    end

    describe '#raw' do
      before do
        item.update_attributes({
          'foo' => 'bar',
          'started_at' => '2014-11-10T10:34:00Z',
          'deleted_at' => nil,
          'located_at' => 'This is not a date, but ends with _at',
        })
      end

      context 'with known attributes' do
        it 'returns the raw value for each attribute' do
          expect(item.raw('foo')).to eq('bar')
          expect(item.raw(:foo)).to eq('bar')

          expect(item.raw('started_at')).to be_a(String)
          expect(item.raw(:started_at)).to be_a(String)
          expect(item.raw('started_at')).to eq('2014-11-10T10:34:00Z')
          expect(item.raw(:started_at)).to eq('2014-11-10T10:34:00Z')

          expect(item.raw('deleted_at')).to be_nil
          expect(item.raw(:deleted_at)).to be_nil

          expect(item.raw('located_at')).to eq('This is not a date, but ends with _at')
          expect(item.raw(:located_at)).to eq('This is not a date, but ends with _at')
        end
      end

      context 'with an unknown attribute' do
        it 'returns nil' do
          expect(item.raw('doesnt_exist')).to be_nil
          expect(item.raw(:doesnt_exist)).to be_nil
        end
      end
    end

    describe '#respond_to?' do
      it 'is true for given args' do
        expect(item.respond_to?('foo')).to be(true)
        expect(item.respond_to?(:foo)).to be(true)
      end

      it 'is false for attrs not given in args' do
        expect(item.respond_to?('bar')).to be(false)
        expect(item.respond_to?(:bar)).to be(false)
      end

      it 'is true for standard methods' do
        expect(item.respond_to?('class')).to be(true)
        expect(item.respond_to?(:class)).to be(true)
      end
    end

    describe '#method and #respond_to_missing?' do
      it 'makes all dynamic attributes available' do
        expect(item.method(:foo)).to be_a(Method)
      end

      it 'also contains all other methods' do
        expect(item.method(:class)).to be_a(Method)
        expect(item.method(:[])).to be_a(Method)
      end
    end

    describe '#methods' do
      it 'lists all dynamic attributes as methods' do
        expect(item.methods).to include(*[
          :bla,
          :blub,
          :deleted_at,
          :foo,
          :located_at,
          :my_hash,
          :started_at,
        ])
      end

      it 'also contains all other methods' do
        expect(item.methods).to include(*Object.new.methods)
        expect(item.methods).to include(:[], :method_missing)
      end

      it 'contains all methods only once' do
        item_with_dynamic_method_overwrite = MyItem.new({'method_missing' => 'other'})
        expect(item_with_dynamic_method_overwrite.methods.count{ |m| m == :method_missing }).to eq(1)
      end
    end

    describe 'finder methods' do
      before do
        item.update_attributes({
          'account_id' => 'a_id_17',
          'event' => 'some event',
          'event_id' => 'e_id_20',

          'activity_ids' => ['act_id_18', 'act_id_19'],
          'mailings' => 'my mailings',
          'mailing_ids' => ['m_id_20'],
        })
      end

      describe 'singular model name method' do
        it 'looks up the ID and fetches the item' do
          expect(item.respond_to?(:account)).to be(true)
          expect(item.methods).to include(:account)
          expect(item.method(:account)).to be_a(Method)

          a17 = double
          expect(Crm).to receive(:find).with('a_id_17').and_return(a17)
          expect(item.account).to be(a17)
        end

        describe 'when it exists as an attribute' do
          it 'returns the value of the attribute' do
            expect(item.respond_to?(:event)).to be(true)
            expect(item.methods).to include(:event)
            expect(item.method(:event)).to be_a(Method)

            expect(item.event).to eq('some event')
          end
        end
      end

      describe 'plural model name method' do
        it 'looks up the IDs and fetches the items' do
          expect(item.respond_to?(:activities)).to be(true)
          expect(item.methods).to include(:activities)
          expect(item.method(:activities)).to be_a(Method)

          act18 = double
          act19 = double
          activities = [act18, act19]
          expect(Crm).to receive(:find).with(['act_id_18', 'act_id_19']).and_return(activities)

          expect(item.activities).to be(activities)
        end

        describe 'when it exists as an attribute' do
          it 'returns the value of the attribute' do
            expect(item.respond_to?(:mailings)).to be(true)
            expect(item.methods).to include(:mailings)
            expect(item.method(:mailings)).to be_a(Method)

            expect(item.mailings).to eq('my mailings')
          end
        end
      end
    end
  end
end

end; end; end
