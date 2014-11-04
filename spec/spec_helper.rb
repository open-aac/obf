lib_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)


require 'obf'
require 'rspec'
require 'net/http'
require 'ostruct'

def external_board
  res = OBF::Utils.obf_shell
  res['id'] = rand(99999)
  res['name'] = 'Unnamed Board'
  res['url'] = 'http://www.boards.com/example'
  res
end
