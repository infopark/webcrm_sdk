require 'spec_helper'

module Crm; module Core; module Mixins

describe ChangeLoggable do
  class MyResource < BasicResource;
    include ChangeLoggable
  end

  let(:now) { "2014-11-10T10:58:43Z" }

  describe '#changes' do
    let(:resource) { MyResource.new({'id' => 'abc'}) }

    it 'returns the changes as an array of Changes' do
      expect(RestApi.instance).to receive(:get).with(
        'my_resources/abc/changes', {'limit' => 23}
      ).and_return({
        "results" => [
          {
            "changed_at" => now,
            "changed_by" => "root",
            "details" => {
              "locality" => {
                "before" => "München",
                "after" => "Berlin"
              },
              "tags" => {
                "before" => ["foo", "bar"],
                "after" => ["another", "tag"]
              }
            }
          },
        ]
      })

      changes = resource.changes(limit: 23)
      change = changes.first

      expect(change).to be_a Core::Mixins::AttributeProvider
      expect(change.changed_at).to eq(Time.parse(now))
      expect(change.changed_at.zone).to eq('MSK')
      expect(change.changed_at.hour).to eq(13)
      expect(change.changed_by).to eq('root')

      detail = change.details['locality']
      expect(detail.before).to eq('München')
      expect(detail.after).to eq('Berlin')

      detail = change.details['tags']
      expect(detail).to be_a Core::Mixins::AttributeProvider
      expect(detail.before).to eq(['foo', 'bar'])
      expect(detail.after).to eq(['another', 'tag'])
    end

    context 'when no limit given' do
      it 'asks for 10 changes' do
        expect(RestApi.instance).to receive(:get).with(
          'my_resources/abc/changes', {'limit' => 10}
        ).and_return({"results" => []})

        resource.changes
      end
    end
  end
end

end; end; end
