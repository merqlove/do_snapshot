# frozen_string_literal: true
RSpec::Matchers.define :be_found_n_times do |str, times|
  match do |output|
    matches = output.scan(str)
    @size = matches.size
    @size == times
  end

  failure_message do |actual|
    "was found #{size} times\nexpected that '#{str}' would be found #{times} times in:\n#{actual}"
  end

  private

  def size
    @size || 0
  end
end
