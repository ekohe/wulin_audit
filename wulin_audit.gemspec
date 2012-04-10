# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "wulin_audit/version"

Gem::Specification.new do |s|
  s.name        = "wulin_audit"
  s.version     = WulinAudit::VERSION
  s.authors     = ["ekohe"]
  s.email       = ["dev@ekohe.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "wulin_audit"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'mongoid', '~> 2.4'
  s.add_dependency 'bson_ext', '~> 1.6.1'
  s.add_dependency 'haml'
  s.add_dependency 'haml-rails'
end
