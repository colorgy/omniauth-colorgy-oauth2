# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/colorgy_oauth2/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-colorgy-oauth2"
  spec.version       = OmniAuth::ColorgyOauth2::VERSION
  spec.authors       = ["Neson"]
  spec.email         = ["neson@dex.tw"]

  spec.summary       = %q{A Colorgy OAuth2 strategy and SSO client helper for OmniAuth.}
  spec.description   = %q{A Colorgy OAuth2 strategy and SSO (Single Sign On/Out) client helper for OmniAuth.}
  spec.homepage      = "https://github.com/colorgy/omniauth-colorgy-oauth2"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'omniauth', '>= 1.1.1'
  spec.add_runtime_dependency 'omniauth-oauth2', '>= 1.1.1'
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
