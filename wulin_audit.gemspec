$:.push File.expand_path("../lib", __FILE__)
require "wulin_audit/version"

Gem::Specification.new do |s|
  s.name = "wulin_audit"
  s.version = WulinAudit::VERSION
  s.authors = ["ekohe"]
  s.email = ["dev@ekohe.com"]
  s.homepage = "https://github.com/ekohe/wulin_audit"
  s.summary = "Audit extension for WulinMaster"
  s.description = "Audit extension for WulinMaster"
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.7"

  s.add_development_dependency "standard"
  s.add_development_dependency "minitest"
  s.add_development_dependency "rails"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "concurrent-ruby"
  s.add_development_dependency "haml-rails"
end
