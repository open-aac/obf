require 'spec_helper'

describe OBF::Utils do
  describe "get_url" do
    it "should make a web request and return the content" do
      res = OpenStruct.new({:headers => {'Content-Type' => 'text/plain'}, :body => "abc"})
      expect(Typhoeus).to receive(:get).and_return(res)
      expect(OBF::Utils.get_url("http://www.google.com")).to eq({
        'content_type' => 'text/plain',
        'data' => 'abc',
        'extension' => '.txt'
      })
    end
  end
  
  describe "image_raw" do
    it "should make a web request and return the content" do
      res = OpenStruct.new({:headers => {'Content-Type' => 'text/plain'}, :body => "abc"})
      expect(Typhoeus).to receive(:get).and_return(res)
      expect(OBF::Utils.image_raw("http://www.google.com")).to eq({
        'data' => 'abc',
        'content_type' => 'text/plain',
        'extension' => '.txt'
      })
    end
  end
  
  describe "fix_color" do
    it "should convert hex to rgb" do
      expect(OBF::Utils.fix_color('#fff', 'rgb')).to eql('rgb(255, 255, 255)')
      expect(OBF::Utils.fix_color('#a0a0a0', 'rgb')).to eql('rgb(160, 160, 160)')
    end

    it "should convert rgb to hex" do
      expect(OBF::Utils.fix_color('rgb(255, 0, 0)')).to eql('ff0000')
      expect(OBF::Utils.fix_color('rgba(255, 0, 0, 0.75)', 'hex')).to eql('ff4040')
      expect(OBF::Utils.fix_color('rgba(255, 0, 0, 0.5)', 'hex')).to eql('ff8080')
      expect(OBF::Utils.fix_color('rgba(255, 0, 0, 0.25)', 'hex')).to eql('ffbfbf')
      expect(OBF::Utils.fix_color('rgba(255, 0, 0, 0.0)', 'hex')).to eql('ffffff')

      expect(OBF::Utils.fix_color('rgb(0, 0, 0)')).to eql('000000')
      expect(OBF::Utils.fix_color('rgba(0, 0, 0, 0.25)', 'hex')).to eql('bfbfbf')
      expect(OBF::Utils.fix_color('rgba(0, 0, 0, 0.5)', 'hex')).to eql('808080')
      expect(OBF::Utils.fix_color('rgba(0, 0, 0, 0.75)', 'hex')).to eql('404040')
      expect(OBF::Utils.fix_color('rgba(0, 0, 0, 0.0)', 'hex')).to eql('ffffff')
      
      expect(OBF::Utils.fix_color('rgba(255, 0, 0, 0.2)', 'hex')).to eql('ffcccc')
      expect(OBF::Utils.fix_color('rgba(31, 52, 143, 0.5)', 'hex')).to eql('8f9ac7')
    end
  end

  describe "image_base64" do
    it "should make a web request and return the content" do
      res = OpenStruct.new({:headers => {'Content-Type' => 'text/text'}, :body => "abc"})
      expect(Typhoeus).to receive(:get).and_return(res)
      expect(OBF::Utils.image_base64("http://www.google.com")).to eq('data:text/text;base64,YWJj')
    end
  end
  
  describe "save_image" do
    it "should extract content type from data uris" do
      path = OBF::Utils.save_image({'data' => "data:text/plain;base64,YWJj"})
      expect(path).to match(/\.txt\.jpg$/)
      expect(File.read(path.sub(/\.jpg$/, '')).size).to eq(3)
    end
    
    it "should have an extension for recognized file types" do
      expect(OBF::Utils).to receive(:'`').and_return(nil)
      path = OBF::Utils.save_image({'data' => "data:text/plain;base64,YWJj", 'content_type' => 'image/png'})
      expect(path).to match(/\.png\.jpg$/)

      expect(OBF::Utils).to receive(:'`').and_return(nil)
      path = OBF::Utils.save_image({'data' => "data:text/plain;base64,YWJj", 'content_type' => 'image/gif'})
      expect(path).to match(/\.gif\.jpg$/)

      expect(OBF::Utils).to receive(:'`').and_return(nil)
      path = OBF::Utils.save_image({'data' => "data:text/plain;base64,YWJj", 'content_type' => 'image/jpeg'})
      expect(path).to match(/\.jpeg\.jpg$/)

      expect(OBF::Utils).to receive(:'`').and_return(nil)
      path = OBF::Utils.save_image({'data' => "data:text/plain;base64,YWJj", 'content_type' => 'image/hippo'})
      expect(path).not_to match(/\..+\.jpg/)
    end
    
    it "should optionally retrieve from the zipper" do
      zipper = {}
      expect(zipper).to receive(:read).with("/pic.png").and_return("data:text/plain;base64,YWJj")
      image = {'path' => '/pic.png'}
      expect(OBF::Utils).to receive(:'`').and_return(nil)
      path = OBF::Utils.save_image(image, zipper)
      expect(path).to match (/\.png\.jpg$/)
    end
    
    it "should write a file for data uris" do
      path = OBF::Utils.save_image({'data' => "data:text/plain;base64,YWJj"})
      expect(path).to match(/\.txt\.jpg$/)
      expect(File.read(path.sub(/\.jpg$/, '')).size).to eq(3)
    end
    
    it "should write a file for image downloads" do
      expect(OBF::Utils).to receive(:get_url).with("http://www.example.com/pic.png").and_return({
        'data' => 'abcdefg',
        'content_type' => 'image/png'
      })
      expect(OBF::Utils).to receive(:'`').and_return(nil)
      path = OBF::Utils.save_image({'url' => "http://www.example.com/pic.png"})
      expect(path).to match(/\.jpg$/)
      expect(File.read(path.sub(/\.jpg$/, '')).size).to eq(7)
    end
    
    it "should call `convert` to resize the image" do
      expect(OBF::Utils).to receive(:get_url).with("http://www.example.com/pic.png").and_return({
        'data' => 'abcdefg',
        'content_type' => 'image/png'
      })
      expect(OBF::Utils).to receive(:'`') do |str|
        expect(str).to match(/^convert .* -resize 200x200 -background \"white\" -gravity center -extent 200x200 .*/)
      end
      path = OBF::Utils.save_image({'url' => "http://www.example.com/pic.png"})
      expect(path).to match(/\.jpg$/)
    end

    it "should call `convert` to resize the image" do
      expect(OBF::Utils).to receive(:get_url).with("http://www.example.com/pic.png").and_return({
        'data' => 'abcdefg',
        'content_type' => 'image/png'
      })
      expect(OBF::Utils).to receive(:'`') do |str|
        expect(str).to match(/^convert .* -resize 200x200 -background \"rgb(255, 0, 255)\" -gravity center -extent 200x200 .*/)
      end
      path = OBF::Utils.save_image({'url' => "http://www.example.com/pic.png"}, 'rgb(255, 0, 255)')
      expect(path).to match(/\.jpg$/)
    end
    
    it "should return nil for unrecognized types" do
      expect(OBF::Utils.save_image({})).to eql(nil)
    end
  end

  describe "sound_raw" do
    it "should make a web request and return the content" do
      res = OpenStruct.new({:headers => {'Content-Type' => 'text/plain'}, :body => "abc"})
      expect(Typhoeus).to receive(:get).and_return(res)
      expect(OBF::Utils.sound_raw("http://www.google.com")).to eq({
        'data' => 'abc',
        'content_type' => 'text/plain',
        'extension' => '.txt'
      })
    end
  end

  describe "sound_base64" do
    it "should make a web request and return the content" do
      res = OpenStruct.new({:headers => {'Content-Type' => 'text/text'}, :body => "abc"})
      expect(Typhoeus).to receive(:get).and_return(res)
      expect(OBF::Utils.sound_base64("http://www.google.com")).to eq('data:text/text;base64,YWJj')
    end
  end

  describe "obf_shell" do
    it "should return a valid shell" do
      expect(OBF::Utils.obf_shell).to eq({
        'format' => 'open-board-0.1',
        'license' => {'type' => 'private'},
        'buttons' => [],
        'grid' => {
          'rows' => 0,
          'columns' => 0,
          'order' => [[]]
        },
        'images' => [],
        'sounds' => []
      })
    end
  end
  
  describe "process_license" do
    it "should process"
  end
  
  describe "process_grid" do
    it "should process"
  end
  
  describe "parse_obf" do
    it "should parse from a simple shell" do
      shell = OBF::Utils.obf_shell
      shell['id'] = '2345'
      shell['name'] = "Cool Board"
      b = OBF::Utils.parse_obf(shell)
      expect(b['id']).to eq('2345')
      expect(b['name']).to eq('Cool Board')
    end
    
    it "should parse from a legacy shell" do
      shell = OBF::Utils.obf_shell
      shell['id'] = '2345'
      shell['name'] = "Cool Board"
      shell['images'] = {
        '1_1' => {'face' => 'asdf'}
      }
      shell['sounds'] = {
        '1_2' => {'nose' => 'qwer'}
      }
      b = OBF::Utils.parse_obf(shell)
      expect(b['id']).to eq('2345')
      expect(b['name']).to eq('Cool Board')
      expect(b['images']).to eq([{'id' => '1_1', 'face' => 'asdf'}])
      expect(b['images_hash']).to eq({'1_1' => {'id' => '1_1', 'face' => 'asdf'}})
      expect(b['sounds']).to eq([{'id' => '1_2', 'nose' => 'qwer'}])
      expect(b['sounds_hash']).to eq({'1_2' => {'id' => '1_2', 'nose' => 'qwer'}})
    end
  end

  describe "add_to_zip" do
    it "should do something worth speccing"
  end

  describe "zip" do
    it "should do something worth speccing"
  end
  
  describe "identify_file" do
    it "should properly identify an obf file" do
      expect(OBF::Utils.identify_file('./spec/samples/aboutme.json')).to eq(:obf)
    end
    it "should properly identify an obz file" do
      expect(OBF::Utils.identify_file('./spec/samples/deep_simple.zip')).to eq(:obz)
    end
    it "should properly identify a p4me file" do
      expect(OBF::Utils.identify_file('./spec/samples/p4me_1.zip')).to eq(:picto4me)
    end
    it "should properly identify a sfy file" do
      expect(OBF::Utils.identify_file('./spec/samples/sfy.data')).to eq(:sfy)
    end
    it "should properly identify a sgrid file" do
      expect(OBF::Utils.identify_file('./spec/samples/grid.xml')).to eq(:sgrid)
    end
  end
end
