module OBF::PNG
  def self.from_pdf(pdf_path, dest_path, opts={})
    resize = ""
    resize = "-resize 600x321 -quality 100" if opts[:resize]
    `convert -density 300 -crop 3160x1690+0+600 +repage #{resize} #{pdf_path} #{dest_path}`
    dest_path
  end
  
  def self.from_obf(obf, dest_path)
    tmp_path = OBF::Utils.temp_path("stash")
    self.from_pdf(OBF::OBF.to_pdf(obf, tmp_path), dest_path)
    File.unlink(tmp_path) if File.exist?(tmp_path)
    dest_path
  end
  
  def self.from_external(board, dest_path)
    tmp_path = OBF::Utils.temp_path("stash")
    self.from_pdf(OBF::External.to_pdf(board, tmp_path), dest_path)
    File.unlink(tmp_path) if File.exist?(tmp_path)
    dest_path
  end
end