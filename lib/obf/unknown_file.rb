module OBF::UnknownFile
  def self.to_external(path)
    type = OBF::Utils.identify_file(path)
    if type == :obf
      OBF::OBF.to_external(path, {})
    elsif type == :obz
      OBF::OBZ.to_external(path, {})
    elsif type == :avz
      OBF::Avz.to_external(path)
    elsif type == :picto4me
      OBF::Picto4me.to_external(path)
    elsif type == :sfy
      OBF::Sfy.to_external(path)
    else
      raise "unrecognized file type"
    end
  end
  
  def self.to_obf_or_obz(path, dest_path_no_extension)
    ext = to_external(path)
    if !ext['boards'] || (ext['boards'] && ext['boards'].length == 1)
      OBF::External.to_obf(ext, dest_path_no_extension + ".obf", {})
    else
      OBF::External.to_obz(ext, dest_path_no_extension + ".obz", {})
    end
  end
  
  def self.to_obf(path, dest_path)
    ext = to_external(path)
    OBF::External.to_obf(ext, dest_path)
  end
  
  def self.to_obz(path, dest_path)
    ext = to_external(path)
    OBF::External.to_obz(ext, dest_path, {})
  end
  
  def self.to_pdf(path, dest_path)
    ext = to_external(path)
    OBF::External.to_pdf(ext, dest_path, {})
  end
  
  def self.to_png(path, dest_path)
    ext = to_external(path)
    OBF::External.to_png(ext, dest_path, {})
  end
end