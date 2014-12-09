require 'typhoeus'
require 'json'
require 'mime/types'
require 'base64'
require 'tempfile'
require 'prawn'

module OBF
  require 'obf/external'
  require 'obf/obf'
  require 'obf/obz'
  require 'obf/pdf'
  require 'obf/png'
  require 'obf/utils'
  require 'obf/validator'
  
  require 'obf/picto4me'
  require 'obf/avz'
  require 'obf/sfy'
  require 'obf/sgrid'
  require 'obf/unknown_file'
end