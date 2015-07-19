# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DoSnapshot::Log do
  include_context 'spec'

  subject(:log) { described_class }

  describe 'will have message' do
    it '#info' do
      expect(DoSnapshot.logger).to respond_to(:info)
      DoSnapshot.logger.info('fff')
      expect(DoSnapshot.logger.buffer).to include('fff')
    end

    it '#debug' do
      expect(DoSnapshot.logger).to respond_to(:debug)
      DoSnapshot.logger.info('fff')
      expect(DoSnapshot.logger.buffer).to include('fff')
    end

    it '#warn' do
      expect(DoSnapshot.logger).to respond_to(:warn)
      DoSnapshot.logger.info('fff')
      expect(DoSnapshot.logger.buffer).to include('fff')
    end

    it '#fatal' do
      expect(DoSnapshot.logger).to respond_to(:fatal)
      DoSnapshot.logger.info('fff')
      expect(DoSnapshot.logger.buffer).to include('fff')
    end

    it '#error' do
      expect(DoSnapshot.logger).to respond_to(:error)
      DoSnapshot.logger.info('fff')
      expect(DoSnapshot.logger.buffer).to include('fff')
    end

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
