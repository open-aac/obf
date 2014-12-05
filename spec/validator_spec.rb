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
  
  describe "validate_obf" do
    it "should validate" do
      val = OBF::Validator.validate_obf('./spec/samples/aboutme.json')
      expect(val[:valid]).to eq(false)
      expect(val[:errors]).to eq(36)
      expect(val[:warnings]).to eq(1)
      res = val[:results]
      expect(res).to be_is_a(Array)
      expect(res.length).to eq(48)
      
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
      check_valid(res, 'buttons[17]')
    end
  end
end
