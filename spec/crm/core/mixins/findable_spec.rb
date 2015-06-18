require 'spec_helper'

module Crm; module Core; module Mixins

describe Findable do
  class MyResource < Crm::Core::BasicResource;
    include Findable
  end

  describe '.find' do
    it 'instantiates itself with the correct ID and calls reload on it' do
      resource = double(MyResource)
      expect(MyResource).to receive(:new).with({'id' => '1a2'}).and_return(resource)
      expect(resource).to receive(:reload).and_return('reload output')

      expect(MyResource.find('1a2')).to eq('reload output')
    end
  end
end

end; end; end
