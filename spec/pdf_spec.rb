require 'spec_helper'

describe OBF::PDF do
  describe "from_obf" do
    it "should render a basic obf" do
      f = Tempfile.new("stash")
      f.puts OBF::Utils.obf_shell.to_json
      f.rewind
      f2 = Tempfile.new("stash")
      OBF::PDF.from_obf(f.path, f2.path)
      f.unlink
      f2.rewind
      expect(f2.size).to be > 2400
      f2.unlink
    end

    it "should render a basic obf with international characters" do
      f = Tempfile.new("stash")
      hash = OBF::Utils.obf_shell
      hash['buttons'] << {'id' => '1', 'label' => 'صرخة'}
      hash['grid']['rows'] = 1
      hash['grid']['columns'] = 1
      hash['grid']['order'] = [['1']]
      f.puts hash.to_json
      f.rewind
      f2 = Tempfile.new("stash")
      OBF::PDF.from_obf(f.path, f2.path)
      f.unlink
      f2.rewind
      expect(f2.size).to be > 2400
      f2.unlink
    end

    it "should render a foreign obf" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      f2 = Tempfile.new("stash")
      OBF::PDF.from_obf("./spec/samples/foreign.obf", path2)
#      `open #{path2}`
      File.unlink path2
    end
  end

  describe "from_obz" do
    it "should render a multi-page obz" do
      b1 = external_board
      b2 = external_board
      b1['buttons'] = [{
        'id' => '1', 'load_board' => {'id' => b2['id']}
      }]
      b1['grid'] = {
        'rows' => 1,
        'columns' => 1,
        'order' => [['1']]
      }
      path1 = OBF::Utils.temp_path("stash")
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      OBF::External.to_obz({'boards' => [b1, b2]}, path1, {})
      OBF::PDF.from_obz(path1, path2)
      File.unlink path1
      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be > 10
      File.unlink path2
    end

    it "should render a headerless multi-page obz" do
      b1 = external_board
      b2 = external_board
      b1['buttons'] = [{
        'id' => '1', 'load_board' => {'id' => b2['id']}, 'label' => 'fish'
      }]
      b1['grid'] = {
        'rows' => 1,
        'columns' => 1,
        'order' => [['1']]
      }
      path1 = OBF::Utils.temp_path("stash")
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      OBF::External.to_obz({'boards' => [b1, b2]}, path1, {})
      OBF::PDF.from_obz(path1, path2, {'headerless' => true})
      File.unlink path1
      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be > 10
#      `open #{path2}`
      File.unlink path2
    end
    
    it "should render a text_on_top multi-page obz" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      OBF::PDF.from_obf('./spec/samples/inline_images.obf', path2, nil, {'text_on_top' => true})
      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be > 20000
#      `open #{path2}`
      File.unlink path2
    end

    it "should render a text_on_top multi-page obz" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      
      expect(OBF::Utils).to receive(:save_image){|img, zipper, bg|
        expect(img['data']).to_not eq(nil)
        if img['id'] == 99
          expect(bg).to eq('#ffffff')
        else
          expect(bg).to eq('#80ff80')
        end
      }.exactly(4).times.and_return(nil)
      OBF::PDF.from_obf('./spec/samples/inline_images.obf', path2, nil, {'transparent_background' => true})

      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be < 30000
#     `open #{path2}`
      File.unlink path2
    end
    
    it "should render a multi-page pre-generated obz" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      expect(OBF::PDF).to receive(:build_page).exactly(3).times
      OBF::PDF.from_obz('./spec/samples/links.obz', path2)
      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be > 10
#      `open #{path2}`
      File.unlink path2
    end

  end

  describe "from_coughdrop" do
    it "should convert to obz and then render that" do
      expect(OBF::OBZ).to receive(:from_external).and_return("/file.obz")
      expect(OBF::PDF).to receive(:from_obz).with("/file.obz", "/file.pdf")
      OBF::PDF.from_external({'boards' => []}, "/file.pdf")
    end
    
    it "should convert to obf if a single record and then render that" do
      expect(OBF::OBF).to receive(:from_external).and_return("/file.obf")
      expect(OBF::PDF).to receive(:from_obf).with("/file.obf", "/file.pdf")
      OBF::PDF.from_external({}, "/file.pdf")
    end
  end  

  describe "to_png" do
    it "should use the png-from-pdf converter" do
      file = "/file.pdf"
      path = "/file.png"
      expect(OBF::PNG).to receive(:from_pdf).with(file, path)
      OBF::PDF.to_png(file, path)
    end
  end
end
