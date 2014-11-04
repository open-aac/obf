require 'spec_helper'

describe OBF::OBZ do
  describe "to_external" do
    it "should use the external-from-obz converter" do
      obz = "/file.obz"
      opts = {}
      expect(OBF::External).to receive(:from_obz).with(obz, opts)
      OBF::OBZ.to_external(obz, opts)
    end
  end
  
  describe "from_external" do
    it "should use the external-to-obz converter" do
      obz = "/file.obz"
      path = "/output.obz"
      expect(OBF::External).to receive(:to_obz).with(obz, path, {'user' => nil})
      OBF::OBZ.from_external(obz, path, {'user' => nil})
    end
  end
  
  describe "to_pdf" do
    it "should use the pdf-from-obz converter" do
      obz = "/file.obz"
      path = "/file.png"
      expect(OBF::PDF).to receive(:from_obz).with(obz, path)
      OBF::OBZ.to_pdf(obz, path)
    end
  end
end
