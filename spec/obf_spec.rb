require 'spec_helper'

describe OBF::OBF do
  describe "to_external" do
    it "should use the external-from-obf converter" do
      obf = "/file.obf"
      opts = {}
      expect(OBF::External).to receive(:from_obf).with(obf, opts)
      OBF::OBF.to_external(obf, opts)
    end
  end
  
  describe "from_external" do
    it "should use the external-to-obf converter" do
      board = external_board
      opts = {}
      expect(OBF::External).to receive(:to_obf).with(board, opts)
      OBF::OBF.from_external(board, opts)
    end
  end
  
  describe "to_pdf" do  
    it "should use the pdf-from-obf converter" do
      obf = "/file.obf"
      path = "/fild.pdf"
      expect(OBF::PDF).to receive(:from_obf).with(obf, path, nil, {})
      OBF::OBF.to_pdf(obf, path)
    end
  end
  
  describe "to_png" do
    it "should use the png-from-obf converter" do
      obf = "/file.obf"
      path = "/fild.pdf"
      expect(OBF::PNG).to receive(:from_obf).with(obf, path)
      OBF::OBF.to_png(obf, path)
    end
  end
end
