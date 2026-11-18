require_relative "lib/wulin_audit/version"

Gem::Specification.new do |s|
  s.name = "wulin_audit"
  s.version = WulinAudit::VERSION
  s.authors = ["Ekohe"]
  s.email = ["dev@ekohe.com"]
  s.homepage = "https://gitlab.ekohe.com/ekohe/wulin/wulin_audit"
  s.summary = "Audit extension for WulinMaster"
  s.description = "Audit extension for WulinMaster"
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.4"

  s.add_dependency "rails", ">= 8.1"
  s.add_dependency "haml-rails"

  s.add_development_dependency "standard"
  s.add_development_dependency "minitest"
  s.add_development_dependency "sqlite3"
end
