# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "infopark_webcrm_sdk"
  spec.version       = begin
    `cd #{File.dirname(__FILE__)} && git describe --tag`.chomp.gsub(/-([0-9]+)-g/, '.\1.').tap do
      raise "git describe failed" unless $?.success?
    end
  end
  spec.authors       = 'Infopark AG'
  spec.email         = 'info@infopark.de'
  spec.summary       = 'Infopark WebCRM SDK'
  spec.description   = %{
    Infopark WebCRM is a professional cloud CRM built for Ruby.
    For more information about Infopark WebCRM, please visit https://infopark.com/.
  }
  spec.homepage      = 'https://infopark.com'
  spec.license       = 'LGPL-3.0'
  spec.files         = ["README.md", "LICENSE", "UPGRADE.md", "config/ca-bundle.crt"] + Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency('actionpack', '~> 4.0')
  spec.add_dependency('activesupport', '~> 4.0')
  spec.add_dependency('multi_json', '~> 1.0')
  spec.add_dependency('multipart-post', '~> 2.0')
  spec.add_dependency('addressable', '~> 2.0')
end
