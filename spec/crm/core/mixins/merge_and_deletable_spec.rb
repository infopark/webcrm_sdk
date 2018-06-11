module Crm; module Core; module Mixins

describe MergeAndDeletable do
  class MyResource < BasicResource;
    include MergeAndDeletable
  end

  describe '#merge_and_delete' do
    let(:resource) { MyResource.new({'id' => 'abc'}) }

    it 'merges and deletes the resource' do
      expect(RestApi.instance).to receive(:post).with(
        'my_resources/abc/merge_and_delete', {'merge_into_id' => '23'}
      )
      resource.merge_and_delete('23')
    end
  end
end

end; end; end
