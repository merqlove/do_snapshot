# -*- encoding : utf-8 -*-
# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DoSnapshot::Log do
  include_context 'environment'

  subject(:log) { described_class }

  describe 'will have message' do
    it('#info')  { logger_respond_to(:info)  }
    it('#debug') { logger_respond_to(:debug) }
    it('#warn')  { logger_respond_to(:warn)  }
    it('#fatal') { logger_respond_to(:fatal) }
    it('#error') { logger_respond_to(:error) }

    it '#blablabla' do
      expect(DoSnapshot.logger).not_to respond_to(:blablabla)
    end

    before :each do
      DoSnapshot.configure do |config|
        config.logger = Logger.new(log_path)
        config.verbose = true
        config.quiet = true
      end
      DoSnapshot.logger = DoSnapshot::Log.new
    end

    def logger_respond_to(type)
      expect(DoSnapshot.logger).to respond_to(type)
      DoSnapshot.logger.send(type, 'fff')
      expect(DoSnapshot.logger.buffer).to include('fff')
    end

    context 'Hashie' do
      it 'warn' do
        expect(Hashie.logger).to respond_to(:warn)
        Hashie.logger.send(:warn, 'fff')
        expect(DoSnapshot.logger.buffer).to include('fff')
      end
    end
  end

  describe 'will work with files' do
    it 'with file' do
      FileUtils.remove_file(log_path, true)

      DoSnapshot.configure do |config|
        config.logger = Logger.new(log_path)
        config.verbose = true
        config.quiet = true
      end
      DoSnapshot.logger = DoSnapshot::Log.new

      expect(File.exist?(log_path)).to be_truthy
    end

    it 'with no file' do
      FileUtils.remove_file(log_path, true)

      DoSnapshot.logger = DoSnapshot::Log.new

      expect(File.exist?(log_path)).to be_falsey
    end

    it 'with no file but logging' do
      FileUtils.remove_file(log_path, true)

      DoSnapshot.logger = DoSnapshot::Log.new

      expect(File.exist?(log_path)).to be_falsey

      expect(DoSnapshot.logger).to respond_to(:info)
      DoSnapshot.logger.info('fff')
      expect(DoSnapshot.logger.buffer).to include('fff')
    end
  end
end
