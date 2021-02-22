Gem::Specification.new do |s|
  s.name        = 'obf'

  s.add_dependency 'json'
  s.add_dependency 'typhoeus'
  s.add_dependency 'mime-types'
  s.add_dependency 'rubyzip'
  s.add_dependency 'prawn'
  s.add_dependency 'CFPropertyList'
  s.add_dependency 'nokogiri'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'ruby-debug'

  s.version     = '0.9.8.37'
  s.date        = '2021-02-22'
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
