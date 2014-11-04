module OBF::OBZ
  def self.to_external(obz, opts)
    OBF::External.from_obz(obz, opts)
  end
  
  def self.from_external(content, dest_path, opts)
    OBF::External.to_obz(content, dest_path, opts)
  end
  
  def self.to_pdf(obz, dest_path)
    OBF::PDF.from_obz(obz, dest_path)
  end
end