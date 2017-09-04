# -*- encoding : utf-8 -*-
# frozen_string_literal: true
require 'spec_helper'

module NewAdapter
  RSpec.describe Adapter do
    include DoSnapshot::RSpec::Environment
    include DoSnapshot::RSpec::ApiV2Helpers
    include DoSnapshot::RSpec::Adapter
  end
end
