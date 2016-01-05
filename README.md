# OBF Parser

[![Gem Version](https://badge.fury.io/rb/obf.svg)](http://badge.fury.io/rb/obf)

This ruby library is to make it easier to handle .obf and .obz files. These files
are part of the Open Board Format, an effort to standardize communication board layouts
for assistive technology and AAC users. The file format is JSON-structured and can
be completely self-contained or reference external URLs.

This library makes it easy to convert to and from .obf and .obz files for generating
images and pdfs, and supports converting some proprietary formats to .obf and .obz.

## Installation
This is packaged as the `obf` rubygem, so you can just add the dependency to
your Gemfile or install the gem on your system:

    gem install obf

To require the library in your project:

    require 'obf'
    
External converters require node. PDF and PNG conversion require imagemagick and node. 
PNG conversion also requires ghostscript.

## Usage

OBF supports multiple conversion schemes, the simplest of which are obf, obz, pdf and png

```ruby
# convert an .obf file to a .pdf
OBF::PDF.from_obf('path/to/input.obf', 'path/to/output.pdf')
# convert an .obz package to a .pdf
OBF::PDF.from_obf('path/to/input.obz', 'path/to/output.pdf')

# convert an .obf file to a .png image
OBF::PNG.from_obf('path/to/input.obf', 'path/to/output.png')
# convert an .obz package to a .png image
OBF::PNG.from_obf('path/to/input.obz', 'path/to/output.png')
```

The gem also supports converting some native packages into OBF files

```ruby
content = OBF::Picto4Me.to_external('path/to/picto4mefile.zip')
OBF::OBZ.from_external(content, 'path/to/output.obz')
```
### External Imports

The <code>external</code> options are the most interesting. Once you understand the
makeup of these external resources, you can generate them from any other system and
easily convert a system's content to .obf, .obz, .pdf or .png.

The makeup of these files closely resembles the layout of an .obf file according to
the .obf spec. You can see an example generator in <code>lib/obf/picto4me.rb</code>,
or dig into the specifics yourself in <code>lib/obf/external.rb</code>.

## Future Work

We've talked about including some utilities to make translation easier. Basically
something that would take an .obf or .obz file and spit out a set of translation strings,
and another something that would take an .obf or .obz file and a set of translation strings
and generate a new, translated result.

## License

Licensed under the MIT License.