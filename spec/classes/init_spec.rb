require 'spec_helper'
describe 'pbis' do

  context 'with defaults for all parameters' do
    it { should contain_class('pbis') }
  end
end
