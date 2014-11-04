Gem::Specification.new do |s|
  s.name        = 'obf'

  s.add_dependency 'json'
  s.add_dependency 'typhoeus'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'ruby-debug'

  s.version     = '0.1'
  s.date        = '2014-11-03'
  s.summary     = "Open Board Format"
  s.extra_rdoc_files = %W(LICENSE)
  s.homepage = %q{http://github.com/CoughDrop/obf}
  s.description = "A parser and converter for .obf and .obz files"
  s.authors     = ["Brian Whitmer"]
  s.email       = 'brian.whitmer@gmail.com'

	s.files = Dir["{lib}/**/*"] + ["LICENSE", "README.md", "Changelog"]
  s.require_paths = %W(lib)

  s.homepage    =
    'http://rubygems.org/gems/obf'
  s.license       = 'MIT'
end

# TODO: need any easy handler for going back and forth with CoughDrop internal format
# to_obf should be easy
# from_obf
