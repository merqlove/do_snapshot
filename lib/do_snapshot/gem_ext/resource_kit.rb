# frozen_string_literal: true
require 'resource_kit'

# TODO: Remove after `resource_kit` gem update.
ResourceKit::Action.class_eval do
  def handler(*response_codes, &block)
    if response_codes.empty?
      handlers[:any] = block
    else
      response_codes.each do |code|
        code = ResourceKit::StatusCodeMapper.code_for(code) unless code.is_a?(Integer)
        handlers[code] = block
      end
    end
  end
end

# TODO: Remove after `resource_kit` gem update.
ResourceKit::ResourceCollection.class_eval do
  def default_handler(*response_codes, &block)
    if response_codes.empty?
      default_handlers[:any] = block
    else
      response_codes.each do |code|
        code = ResourceKit::StatusCodeMapper.code_for(code) unless code.is_a?(Integer)
        default_handlers[code] = block
      end
    end
  end
end
