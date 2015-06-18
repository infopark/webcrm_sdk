require 'spec_helper'

module Crm; module Core; module Mixins

describe Inspectable do
  class MyClass;
    include Inspectable
    inspectable :id, :list

    def id
      'foo'
    end

    def list
      ['ab', 'cd']
    end
  end

  describe '#inspect' do
    let(:item) { MyClass.new }

    it 'returns an one-liner inspect' do
      expect(item.inspect).to eq(
        "#<Crm::Core::Mixins::MyClass id=\"foo\", list=[\"ab\", \"cd\"]>"
      )
    end
  end
end

end; end; end
