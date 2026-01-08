# frozen_string_literal: true

require_relative '../lib/exchange_it'

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec/specs.txt'
  config.define_derived_metadata(file_path: %r{exchange_it/utils}) do |meta|
    meta[:utils] = true
  end
  config.filter_run_excluding :linux_only unless RUBY_PLATFORM.include?('x86_64-linux')
end
