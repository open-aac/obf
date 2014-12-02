Gem::Specification.new do |s|
  s.name        = 'obf'

  s.add_dependency 'json'
  s.add_dependency 'typhoeus'
  s.add_dependency 'mime-types'
  s.add_dependency 'rubyzip'
  s.add_dependency 'prawn'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'ruby-debug'

  s.version     = '0.2.9'
  s.date        = '2014-12-02'
  s.summary     = "Open Board Format"
  s.extra_rdoc_files = %W(LICENSE)
  s.homepage = %q{http://github.com/CoughDrop/obf}
  s.description = "A parser and converter for .obf and .obz files"
  s.authors     = ["Brian Whitmer"]
  s.email       = 'brian.whitmer@gmail.com'

	s.files = Dir["{lib}/**/*"] + ["LICENSE", "README.md"]
  s.require_paths = %W(lib)

  s.homepage    = 'https://github.com/CoughDrop/obf'
  s.license     = 'MIT'
end

# TODO: need any easy handler for going back and forth with CoughDrop internal format
# to_obf should be easy
# from_obf
