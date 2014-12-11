require 'spec_helper'

describe OBF::UnknownFile do
  describe "to_obf_or_obz" do
    it "should call to_obf if a single board" do
      ext = {'id' => '123'}
      pre_path = OBF::Utils.temp_path("file")
      post_path = OBF::Utils.temp_path("file")
      expect(OBF::UnknownFile).to receive(:to_external).with(pre_path).and_return(ext)
      expect(OBF::External).to receive(:to_obf).with(ext, post_path + ".obf", {})
      OBF::UnknownFile.to_obf_or_obz(pre_path, post_path)
    end
    
    it "should call to_obf if a board list with only one result" do
      ext = {'boards' => [{}]}
      pre_path = OBF::Utils.temp_path("file")
      post_path = OBF::Utils.temp_path("file")
      expect(OBF::UnknownFile).to receive(:to_external).with(pre_path).and_return(ext)
      expect(OBF::External).to receive(:to_obf).with(ext, post_path + ".obf", {})
      OBF::UnknownFile.to_obf_or_obz(pre_path, post_path)
    end
    
    it "should call to_obz if a board list with more than one result" do
      ext = {'boards' => [{}, {}]}
      pre_path = OBF::Utils.temp_path("file")
      post_path = OBF::Utils.temp_path("file")
      expect(OBF::UnknownFile).to receive(:to_external).with(pre_path).and_return(ext)
      expect(OBF::External).to receive(:to_obz).with(ext, post_path + ".obz", {})
      OBF::UnknownFile.to_obf_or_obz(pre_path, post_path)
    end
  end
  
  describe "avz" do
  end
  
  describe "obz" do
    it "should convert to external" do
      ext = OBF::UnknownFile.to_external("./spec/samples/deep_simple.zip")
      expect(ext).not_to eql(nil)
      expect(ext['boards'].length).to eq(97)
    end
    
    it "should convert to obf" do
      ext = OBF::UnknownFile.to_external("./spec/samples/deep_simple.zip")
      path = OBF::Utils.temp_path("file.obf")
      expect(OBF::External).to receive(:to_obf).with(ext, path).and_return(path)
      res = OBF::UnknownFile.to_obf("./spec/samples/deep_simple.zip", path)
      expect(res).to eql(path)
    end
    
    it "should convert to obz" do
      ext = OBF::UnknownFile.to_external("./spec/samples/deep_simple.zip")
      path = OBF::Utils.temp_path("file.obz")
      expect(OBF::External).to receive(:to_obz).with(ext, path, {}).and_return(path)
      res = OBF::UnknownFile.to_obz("./spec/samples/deep_simple.zip", path)
      expect(res).to eql(path)
    end
    
    it "should convert to pdf" do
      ext = OBF::UnknownFile.to_external("./spec/samples/deep_simple.zip")
      path = OBF::Utils.temp_path("file.pdf")
      expect(OBF::External).to receive(:to_pdf).with(ext, path, {}).and_return(path)
      res = OBF::UnknownFile.to_pdf("./spec/samples/deep_simple.zip", path)
      expect(res).to eql(path)
    end
    
    it "should convert to pdf with multiple pages" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      expect(OBF::PDF).to receive(:build_page).exactly(3).times
      path = OBF::UnknownFile.to_pdf('./spec/samples/links.obz', path2 + '.pdf')
      expect(File.exist?(path)).to eq(true)
      expect(File.size(path)).to be > 10
    end
    
    it "should convert to pdf with path images" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      expect(OBF::Utils).to receive(:save_image).exactly(2).times
      path = OBF::UnknownFile.to_pdf('./spec/samples/path_images.obz', path2 + '.pdf')
      expect(File.exist?(path)).to eq(true)
      expect(File.size(path)).to be > 10
    end
    
    it "should convert to pdf with lots of settings" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      path = OBF::UnknownFile.to_pdf('./spec/samples/lots_of_stuff.obz', path2 + '.pdf')
      expect(File.exist?(path)).to eq(true)
      expect(File.size(path)).to be > 10
    end
    
    it "should convert to png" do
      ext = OBF::UnknownFile.to_external("./spec/samples/deep_simple.zip")
      path = OBF::Utils.temp_path("file.png")
      expect(OBF::External).to receive(:to_png).with(ext, path, {}).and_return(path)
      res = OBF::UnknownFile.to_png("./spec/samples/deep_simple.zip", path)
      expect(res).to eql(path)
    end
  end
  
  describe "obf" do
    it "should convert to external" do
      ext = OBF::UnknownFile.to_external("./spec/samples/aboutme.json")
      expect(ext).not_to eql(nil)
      expect(ext['name']).to eq("CommuniKate About Me")
    end
    
    it "should convert to obf" do
      ext = OBF::UnknownFile.to_external("./spec/samples/aboutme.json")
      path = OBF::Utils.temp_path("file.obf")
      expect(OBF::External).to receive(:to_obf).with(ext, path).and_return(path)
      res = OBF::UnknownFile.to_obf("./spec/samples/aboutme.json", path)
      expect(res).to eql(path)
    end
    
    it "should convert to obz" do
      ext = OBF::UnknownFile.to_external("./spec/samples/aboutme.json")
      path = OBF::Utils.temp_path("file.obz")
      expect(OBF::External).to receive(:to_obz).with(ext, path, {}).and_return(path)
      res = OBF::UnknownFile.to_obz("./spec/samples/aboutme.json", path)
      expect(res).to eql(path)
    end
    
    it "should convert to pdf" do
      ext = OBF::UnknownFile.to_external("./spec/samples/aboutme.json")
      path = OBF::Utils.temp_path("file.pdf")
      expect(OBF::External).to receive(:to_pdf).with(ext, path, {}).and_return(path)
      res = OBF::UnknownFile.to_pdf("./spec/samples/aboutme.json", path)
      expect(res).to eql(path)
    end
    
    it "should convert to png" do
      ext = OBF::UnknownFile.to_external("./spec/samples/aboutme.json")
      path = OBF::Utils.temp_path("file.png")
      expect(OBF::External).to receive(:to_png).with(ext, path, {}).and_return(path)
      res = OBF::UnknownFile.to_png("./spec/samples/aboutme.json", path)
      expect(res).to eql(path)
    end
  end
  
  describe "picto4me" do
    it "should convert to external" do
      ext = OBF::UnknownFile.to_external("./spec/samples/p4me_1.zip")
      expect(ext).not_to eql(nil)
      expect(ext['boards'].length).to eq(3)
    end
    
    it "should convert to obf" do
      path = OBF::Utils.temp_path("file.obf")
      expect(OBF::UnknownFile).to receive(:to_external).with("./spec/samples/p4me_1.zip").and_return({})
      expect(OBF::External).to receive(:to_obf).with({}, path).and_return(path)
      res = OBF::UnknownFile.to_obf("./spec/samples/p4me_1.zip", path)
      expect(res).to eql(path)
    end
    
    it "should convert to obz" do
      path = OBF::Utils.temp_path("file.obz")
      expect(OBF::UnknownFile).to receive(:to_external).with("./spec/samples/p4me_1.zip").and_return({})
      expect(OBF::External).to receive(:to_obz).with({}, path, {}).and_return(path)
      res = OBF::UnknownFile.to_obz("./spec/samples/p4me_1.zip", path)
      expect(res).to eql(path)
    end
    
    it "should convert to pdf" do
      path = OBF::Utils.temp_path("file.pdf")
      expect(OBF::UnknownFile).to receive(:to_external).with("./spec/samples/p4me_1.zip").and_return({})
      expect(OBF::External).to receive(:to_pdf).with({}, path, {}).and_return(path)
      res = OBF::UnknownFile.to_pdf("./spec/samples/p4me_1.zip", path)
      expect(res).to eql(path)
    end
    
    it "should convert to png" do
      path = OBF::Utils.temp_path("file.png")
      expect(OBF::UnknownFile).to receive(:to_external).with("./spec/samples/p4me_1.zip").and_return({})
      expect(OBF::External).to receive(:to_png).with({}, path, {}).and_return(path)
      res = OBF::UnknownFile.to_png("./spec/samples/p4me_1.zip", path)
      expect(res).to eql(path)
    end
  end
  
  describe "sfy" do
    it "should convert to external" do
      ext = OBF::UnknownFile.to_external("./spec/samples/sfy.data")
      expect(ext).not_to eql(nil)
      expect(ext['boards'].length).to eq(6)
    end
    
    it "should convert to obf" do
      path = OBF::Utils.temp_path("file.obf")
      expect(OBF::UnknownFile).to receive(:to_external).with("./spec/samples/sfy.data").and_return({})
      expect(OBF::External).to receive(:to_obf).with({}, path).and_return(path)
      res = OBF::UnknownFile.to_obf("./spec/samples/sfy.data", path)
      expect(res).to eql(path)
    end
    
    it "should convert to obz" do
      path = OBF::Utils.temp_path("file.obz")
      expect(OBF::UnknownFile).to receive(:to_external).with("./spec/samples/sfy.data").and_return({})
      expect(OBF::External).to receive(:to_obz).with({}, path, {}).and_return(path)
      res = OBF::UnknownFile.to_obz("./spec/samples/sfy.data", path)
      expect(res).to eql(path)
    end
    
    it "should convert to pdf" do
      path = OBF::Utils.temp_path("file.pdf")
      expect(OBF::UnknownFile).to receive(:to_external).with("./spec/samples/sfy.data").and_return({})
      expect(OBF::External).to receive(:to_pdf).with({}, path, {}).and_return(path)
      res = OBF::UnknownFile.to_pdf("./spec/samples/sfy.data", path)
      expect(res).to eql(path)
    end
    
    it "should convert to png" do
      path = OBF::Utils.temp_path("file.png")
      expect(OBF::UnknownFile).to receive(:to_external).with("./spec/samples/sfy.data").and_return({})
      expect(OBF::External).to receive(:to_png).with({}, path, {}).and_return(path)
      res = OBF::UnknownFile.to_png("./spec/samples/sfy.data", path)
      expect(res).to eql(path)
    end
  end
end
