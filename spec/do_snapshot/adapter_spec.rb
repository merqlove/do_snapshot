# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe DoSnapshot::Adapter do
  include_context 'environment'

  module AdapterFactory
    class Adapter # rubocop:disable Style/Documentation
      def initialize(_ = {}); end
    end
  end

  subject(:adapter) { described_class }

  describe '#api' do
    it 'when adapter' do
      api = adapter.api(2)
      expect(api).to be_a_kind_of(DoSnapshot::Adapter::DigitaloceanV2)
    end

    it 'when custom adapter' do
      api = adapter.api('AdapterFactory::Adapter')
      expect(api).to be_a_kind_of(AdapterFactory::Adapter)
    end

    it 'when error' do
      expect { adapter.api(1) }.to raise_exception(DoSnapshot::NoProtocolError)
    end
  end
end
