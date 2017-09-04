# -*- encoding : utf-8 -*-
# frozen_string_literal: true
require 'spec_helper'

RSpec.describe NewAdapter do
  include DoSnapshot::RSpec::Environment
  include DoSnapshot::RSpec::ApiV2Helpers
  include DoSnapshot::RSpec::Adapter
end
