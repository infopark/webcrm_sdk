require_relative 'support/ca_bundle'

desc "Build ca_bundle.crt (used to verify SSL certificates)"
task :build_ca_bundle => "config" do
  cert_path = "config/ca-bundle.crt"
  ca_bundle = CaBundle.new(cert_path)
  unless ENV['TRAVIS']
    ca_bundle.create
    unless %x{git status -- #{cert_path}}.include?("nothing to commit")
      raise "config/ca-bundle.crt changed. Please commit before proceeding!"
    end
  end
  ca_bundle.verify('https://demo.crm.infopark.net:443')
  ca_bundle.verify('https://ip-saas-crm-blobs.s3.amazonaws.com:443')
end

directory 'config'
