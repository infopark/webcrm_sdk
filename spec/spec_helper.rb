require 'infopark_webcrm_sdk'
require 'webmock/rspec'
require 'infopark_crm_connector'
require 'patience'

# only enable WebMock when needed!
WebMock.disable!

# Use Moscow time, since it does not change between summer/winter time and it's not Berlin
Time.zone = 'Moscow'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  I18n.enforce_available_locales = true
  # # These two settings work together to allow you to limit a spec run
  # # to individual examples or groups you care about by tagging them with
  # # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # # get run.
  # config.filter_run :focus
  # config.run_all_when_everything_filtered = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # # Print the 10 slowest examples and example groups at the
  # # end of the spec run, to help surface which specs are running
  # # particularly slow.
  # config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
    expectations.syntax = :expect
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
    mocks.syntax = :expect

    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended.
    mocks.verify_partial_doubles = true
  end

  config.before(:all) do
    Crm.configure do |c|
      c.api_key = ENV['CRM_API_KEY']
      c.login = ENV['CRM_LOGIN']
      c.tenant = ENV['CRM_TENANT']
      c.endpoint = ENV['CRM_ENDPOINT']
      # c.logger = Logger.new($stderr)
    end
  end
end

module CrmSetup
  def self.define_support_case
    Crm::Type.create({
      id: 'support-case',
      item_base_type: 'Activity',
      states: ['created', 'registered'],
    })
  rescue Crm::Errors::InvalidValues
  end

  def self.define_base_event
    Crm::Type.create({
      id: 'base-event',
      item_base_type: 'Event',
    })
  rescue Crm::Errors::InvalidValues
  end

  def self.define_newsletter_mailing
    Crm::Type.create({
      id: 'newsletter',
      item_base_type: 'Mailing',
    })
  rescue Crm::Errors::InvalidValues
  end

  def self.set_api_user_email
    api_user = Crm::Contact.where(:login, :equals, ENV['CRM_LOGIN']).first
    if api_user.email.blank?
      api_user.update(email: 'success@simulator.amazonses.com')
    end
  end
end
