# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "wulin_audit/version"

Gem::Specification.new do |s|
  s.name        = "wulin_audit"
  s.version     = WulinAudit::VERSION
  s.authors     = ["ekohe"]
  s.email       = ["dev@ekohe.com"]
  s.homepage    = ""
  s.summary     = %q{Audit extension for WulinMaster}
  s.description = %q{Audit extension for WulinMaster}

  s.rubyforge_project = "wulin_audit"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'bson_ext'
  s.add_dependency 'haml'
  s.add_dependency 'haml-rails'
end
