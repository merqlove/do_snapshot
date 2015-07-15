# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DoSnapshot::Mail do
  include_context 'spec'

  describe 'will send mail with options' do
    it '#notify' do
      DoSnapshot::Mail.reset_options
      DoSnapshot::Mail.load_options(opts: mail_options, smtp: smtp_options)
      expect { DoSnapshot::Mail.notify }.not_to raise_error
      expect(DoSnapshot::Mail.smtp[:address]).to eq(smtp_options[:address])
    end
  end
end
