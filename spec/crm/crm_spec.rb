require 'spec_helper'

module Crm

describe '#configure' do
  context 'without settings' do
    it 'complains about missing settings' do
      expect { Crm.configure {} }.to raise_error(/Missing required configuration key/)
    end
  end
end

end
