require 'dotenv/load'
require 'bundler/setup'
Bundler.setup

require_relative '../lib/anapay_to_zaim'
require_relative '../lib/email_fetcher'
require_relative '../lib/zaim_api_client'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end