module OBF::OBF
  def self.to_external(obf, opts)
    OBF::External.from_obf(obf, opts)
  end
  
  def self.from_external(board, dest_path)
    OBF::External.to_obf(board, dest_path)
  end
  
  def self.to_pdf(obf, dest_path)
    OBF::PDF.from_obf(obf, dest_path)
  end
  
  def self.to_png(obf, dest_path)
    OBF::PNG.from_obf(obf, dest_path)
  end
end