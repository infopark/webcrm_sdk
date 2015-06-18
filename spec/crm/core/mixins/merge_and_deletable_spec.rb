require 'spec_helper'

module Crm; module Core; module Mixins

describe MergeAndDeletable do
  class MyResource < BasicResource;
    include MergeAndDeletable
  end

  let(:now) { Time.now.utc.xmlschema }

  describe '#merge_and_delete' do
    let(:resource) { MyResource.new({'id' => 'abc'}) }

    it 'merges and deletes the resource' do
      expect(RestApi.instance).to receive(:post).with(
        'my_resources/abc/merge_and_delete', {'merge_into_id' => '23'}
      ).and_return({
        'id' => 'abc',
        'merged_into_id' => '23',
        'deleted_at' => now,
      })
      expect(resource.merge_and_delete('23')).to be(resource)

      expect(resource.merged_into_id).to eq('23')
      expect(resource.deleted_at).to eq(now)
    end
  end
end

end; end; end
