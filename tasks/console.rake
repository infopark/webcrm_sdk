task :console do
  require 'pry'
  require 'infopark_webcrm_sdk'
  ARGV.clear

  I18n.enforce_available_locales = true

  Crm.configure do |c|
    c.api_key = ENV['CRM_API_KEY']
    c.endpoint = ENV['CRM_ENDPOINT']
    c.login = ENV['CRM_LOGIN']
    c.tenant = ENV['CRM_TENANT']
    # c.logger = Logger.new($stderr)
  end

  Pry.start
end
