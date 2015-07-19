# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DoSnapshot::Mail do
  include_context 'spec'

  subject(:mail) { described_class }

  describe 'will send mail with options' do
    it '#notify' do
      mail = DoSnapshot.mailer.notify
      expect(mail).not_to be_falsey
      expect(mail.delivery_method.settings[:address]).to eq(smtp_options[:address])
      expect(mail.delivery_method.settings[:port]).to eq(smtp_options[:port])
      expect(mail.delivery_method.settings[:user_name]).to eq(smtp_options[:user_name])
      expect(mail.delivery_method.settings[:password]).to eq(smtp_options[:password])
      expect(mail.header.fields).to include(::Mail::Field.new('From', mail_options[:from], 'UTF-8'))
      expect(mail.header.fields).to include(::Mail::Field.new('To', mail_options[:to], 'UTF-8'))
    end

    before :each do
      DoSnapshot.configure do |config|
        config.mailer = mail.new(opts: mail_options, smtp: smtp_options)
      end
      DoSnapshot.mailer = DoSnapshot.config.mailer
      DoSnapshot.logger = DoSnapshot::Log.new
    end
  end
end
