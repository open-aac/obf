require 'spec_helper'

describe OBF::Validator do
  def check_valid(res, type)
    res = res.select{|r| r['type'] == type}
    expect(res.length).to eq(1)
    expect(res[0]['valid']).to eq(true)
    res[0]
  end
  
  def check_invalid(res, type)
    res = res.select{|r| r['type'] == type}
    expect(res.length).to eq(1)
    expect(res[0]['valid']).to eq(false)
    res[0]
  end
  
  describe "validate_file" do
    it "should handle .obf files" do
      val = OBF::Validator.validate_file('./spec/samples/aboutme.json')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(37)
      expect(val[:warnings]).to eq(2)
      res = val[:results]
      expect(res).to be_is_a(Array)
      expect(res.length).to eq(50)
    end
    
    it "should handle .obz files" do
      val = OBF::Validator.validate_obz('./spec/samples/deep_simple.zip')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(2955)
      expect(val[:warnings]).to eq(107)
      res = val[:results]
      expect(res).to be_is_a(Array)
      expect(res.length).to eq(106)
    end

    it "should handle .obz files with errors" do
      val = OBF::Validator.validate_file('./spec/samples/pageset.obz')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(15)
      expect(val[:warnings]).to eq(81)
      res = val[:results]
      expect(res).to be_is_a(Array)
      expect(res.length).to eq(89)
      expect(val[:sub_results].map{|r| r[:errors] }).to eq([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0])
      expect(val[:sub_results].map{|r| r[:warnings] }).to eq([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
      errors = val[:results].select{|r| !r['valid'] } 
      errors += val[:sub_results].map{|sr| sr[:results].select{|r| !r['valid'] } }.flatten
      expect(errors.length).to eq(15)
      expect(errors[0]['error']).to eq("button.load_board.path references boards/special::unfinnished.obf which isn't found in the zipped file")
    end

    it "should not error on unrecognized files" do
      val = OBF::Validator.validate_file('./obf.gemspec')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(1)
      expect(val[:results].length).to eq(1)
      expect(val[:results][0]['valid']).to eq(false)
      expect(val[:results][0]['error']).to eq('file must be a single .obf JSON file or a .obz zip package')

      val = OBF::Validator.validate_file('./spec/samples/sfy.data')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(1)
      expect(val[:results].length).to eq(1)
      expect(val[:results][0]['valid']).to eq(false)
      expect(val[:results][0]['error']).to eq('file must be a single .obf JSON file or a .obz zip package')

      val = OBF::Validator.validate_file('./spec/samples/p4me_1.zip')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(1)
      expect(val[:results].length).to eq(1)
      expect(val[:results][0]['valid']).to eq(false)
      expect(val[:results][0]['error']).to eq('file must be a single .obf JSON file or a .obz zip package')

      val = OBF::Validator.validate_file('./spec/samples/hash.json')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(1)
      expect(val[:results].length).to eq(2)
      expect(val[:results][0]['valid']).to eq(false)
      expect(val[:results][0]['error']).to eq('file must be a single .obf JSON file or a .obz zip package')
      expect(val[:results][1]['valid']).to eq(false)
      expect(val[:results][1]['error']).to eq('file contains a JSON object but it does not appear to be an OBF-formatted object')

      val = OBF::Validator.validate_file('./spec/samples/array.json')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(1)
      expect(val[:results].length).to eq(2)
      expect(val[:results][0]['valid']).to eq(false)
      expect(val[:results][0]['error']).to eq('file must be a single .obf JSON file or a .obz zip package')
      expect(val[:results][1]['valid']).to eq(false)
      expect(val[:results][1]['error']).to eq('file contains valid JSON, but a type other than Object. OBF files do not support arrays, strings, etc. as the root object')

      val = OBF::Validator.validate_file('./spec/samples/string.json')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(1)
      expect(val[:results].length).to eq(2)
      expect(val[:results][0]['valid']).to eq(false)
      expect(val[:results][0]['error']).to eq('file must be a single .obf JSON file or a .obz zip package')
      expect(val[:results][1]['valid']).to eq(false)
      expect(val[:results][1]['error']).to eq('file contains valid JSON, but a type other than Object. OBF files do not support arrays, strings, etc. as the root object')
    end
  end
  
  describe "validate_obf" do
    it "should validate" do
      val = OBF::Validator.validate_obf('./spec/samples/aboutme.json')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(37)
      expect(val[:warnings]).to eq(2)
      res = val[:results]
      expect(res).to be_is_a(Array)
      expect(res.length).to eq(50)
      
      record = check_valid(res, 'filename')
      expect(record['warnings'].length).to eq(1)
      expect(record['warnings'][0]).to eq("filename should end with .obf")
      
      check_valid(res, 'valid_json')
      check_valid(res, 'to_external')
      check_valid(res, 'format_version')
      check_valid(res, 'id')
      check_invalid(res, 'locale')
      check_valid(res, 'extras')
      record = check_valid(res, 'description')
      expect(record['warnings'].length).to eq(1)
      expect(record['warnings'][0]).to eq("description_html attribute is recommended")
      check_valid(res, 'buttons')
      check_valid(res, 'grid')
      record = check_valid(res, 'grid_ids')
      expect(record['warnings']).to eq(nil)
      check_valid(res, 'images')
      record = check_invalid(res, 'image[0]')
      expect(record['error']).to eq("image.width must be a valid positive number")
      check_valid(res, 'sounds')
      record = check_invalid(res, 'buttons[0]')
      expect(record['error']).to eq("button.background_color must be a valid rgb or rgba value if defined (\"#ffff32\" is invalid)")
      record = check_invalid(res, 'buttons[17]')
      expect(record['error']).to eq("button.load_board.path is set but this isn't a zipped file")
    end
    
    it "should error on non-obf file" do
      val = OBF::Validator.validate_obf('./spec/samples/sfy.data')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(1)
      expect(val[:warnings]).to eq(1)
      res = val[:results]
      expect(res).to be_is_a(Array)
      expect(res.length).to eq(2)
    end
  end
  
  describe "validate_obz" do
    it "should validate" do
      val = OBF::Validator.validate_obz('./spec/samples/deep_simple.zip')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(2955)
      expect(val[:warnings]).to eq(107)
      res = val[:results]
      expect(res).to be_is_a(Array)
      expect(res.length).to eq(106)
      
      record = check_valid(res, 'filename')
      expect(record['warnings'][0]).to eq("filename should end with .obz")
      check_valid(res, 'zip')
      check_valid(res, 'manifest')
      check_valid(res, 'manifest_format')
      check_valid(res, 'manifest_root')
      check_valid(res, 'manifest_paths')
      check_valid(res, 'manifest_extras')
      check_valid(res, 'manifest_boards[aboutme]')
      
      expect(val[:sub_results].length).to eq(98)
      r = val[:sub_results][0]
      expect(r[:filename]).to eq('boards/aboutme.obf')
      expect(r[:filesize]).to eq(10632)
      expect(r[:valid]).to eq(false)
      expect(r[:errors]).to eq(38)
      expect(r[:warnings]).to eq(1)
    end
    
    it "should error on non-zip file" do
      val = OBF::Validator.validate_obz('./spec/samples/sfy.data')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(1)
      expect(val[:warnings]).to eq(1)
      res = val[:results]
      expect(res).to be_is_a(Array)
      expect(res.length).to eq(2)
    end
  end
end
