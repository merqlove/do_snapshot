# -*- encoding : utf-8 -*-
# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DoSnapshot::Adapter::Abstract do
  include DoSnapshot::RSpec::Environment

  subject(:api) { described_class }

  describe '.initialize' do
    describe '#delay' do
      let(:delay) { 5 }
      let(:instance) { api.new(delay: delay) }
      it('with custom delay') { expect(instance.delay).to eq delay }
    end

    describe '#timeout' do
      let(:timeout) { 5 }
      let(:instance) { api.new(timeout: timeout) }
      it('with custom timeout') { expect(instance.timeout).to eq timeout }
    end
  end

  describe '#wait_wrap' do
    let(:instance) { api.new }
    it('with custom timeout') do
      expect do
        instance.send(:wait_wrap, 1, 'Event Id: 1') { fail StandardError, 'Some Error' }
      end.not_to raise_exception
    end
  end

  describe '#wait_event' do
    let(:delay) { 5 }
    let(:timeout) { 5 }
    let(:instance) { api.new(delay: delay, timeout: timeout) }
    it('with custom timeout') do
      expect do
        instance.send(:wait_event, 5)
      end.not_to raise_exception
    end
  end
end
