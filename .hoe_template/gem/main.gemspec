# -*- encoding: utf-8 -*-
<% lib_name = File.basename("../lib/main_class.rb")
lib_name.sub!(/#{File.extname(lib_name)}$/ , "")
class_name = lib_name
module_name = File.basename(File.dirname(File.dirname(File.realdirpath(__FILE__))))
begin
  require 'facets'
  class_name = class_name.upper_camelcase
  module_name = module_name.upper_camelcase
rescue
end
%>
#$:.push File.expand_path("../lib", __FILE__)
require "<%= lib_name %>"

Gem::Specification.new do |s|
  s.name        = "<%= lib_name %>"
  s.version     = <%= module_name %>::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Sandor Szücs"]
  s.email       = ["sandor.szuecs@fu-berlin.de"]
  s.homepage    = "http://www.github.com/szuecs/<%= lib_name %>"
  s.summary     = %q{TODO}
  s.description = %q{TODO}

#  s.add_runtime_dependency "launchy"
#  s.add_development_dependency "rspec", "~>2.5.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
