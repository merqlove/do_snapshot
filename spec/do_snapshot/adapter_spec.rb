# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe DoSnapshot::Adapter do
  include_context 'environment'

  subject(:adapter) { described_class }

  describe '#api' do
    it 'when adapter' do
      api = adapter.api(2)
      expect(api).to be_a_kind_of(DoSnapshot::Adapter::DigitaloceanV2)
    end

    it 'when error' do
      expect { adapter.api(1) }.to raise_exception(DoSnapshot::NoProtocolError)
    end
  end
end
