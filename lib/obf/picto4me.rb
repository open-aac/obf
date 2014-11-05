module OBF::Picto4me
  def self.to_external(zip_path)
    boards = []
    images = []
    sounds = []
    OBF::Utils.load_zip(zip_path) do |zipper|
      # open contents, parse JSON, load files into memory, etc...
    end
    images.uniq!
    sounds.uniq!
    return {
      'boards' => boards,
      'images' => images,
      'sounds' => sounds
    }
  end
end