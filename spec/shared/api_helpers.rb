# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.shared_context 'api_helpers' do
  # Stub helpers
  #
  def stub_with_id(request, id, fixture, status = 200)
    return unless request && fixture && id
    stub_request(:get, url_with_id(request, id))
      .to_return(status: status, body: fixture(fixture))
  end

  def stub_without_id(request, fixture, status = 200)
    return unless request && fixture
    stub_request(:get, request)
      .to_return(status: status, body: fixture(fixture))
  end

  def stub_with_id_name(request, id, name, fixture, status = 200)
    return unless request && fixture && id && name
    stub_request(:get, url_with_id_name(request, id, name))
      .to_return(status: status, body: fixture(fixture))
  end

  # Url helpers
  #
  def url_with_id(request, id)
    return unless request && id
    request.sub('[id]', id.to_s)
  end

  def url_with_event_id(request, droplet_id, id)
    return unless request && id && droplet_id
    request.sub('[id]', id.to_s).sub('[droplet_id]', droplet_id.to_s)
  end

  def url_with_id_name(request, id, name)
    return unless request && id && name
    request.sub('[id]', id.to_s).sub('[name]', name)
  end
end
