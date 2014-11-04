module OBF::Utils
#   def self.board_to_remote(board, user, file_type, include)
#     OBF::Utils.update_current_progress(0.2, :converting_file)
#     # TODO: key off just the last change id for the board(s) when building the
#     # filename, return existing filename if it exists and isn't about to expire
#     path = OBF::Utils.temp_path("stash")
# 
#     content_type = nil
#     if file_type == 'obf'
#       content_type = 'application/obf'
#     elsif file_type == 'obz'
#       content_type = 'application/obz'
#     elsif file_type == 'pdf'
#       content_type = 'application/pdf'
#     else
#       raise "Unrecognized conversion type: #{file_type}"
#     end
#     key = Security.sha512(board.id.to_s, 'board_id')
#     filename = "board_" + board.current_revision + "." + file_type.to_s
#     remote_path = "downloads/#{key}/#{filename}"
#     url = Uploader.check_existing_upload(remote_path)
#     return url if url
#     OBF::Utils.update_current_progress(0.3, :converting_file)
#     
#     OBF::Utils.as_progress_percent(0.3, 0.8) do
#       if file_type == 'obz'
#         if include == 'all'
#           OBF::CoughDrop.to_obz(board, path, {'user' => user})
#         else
#           OBF::CoughDrop.to_obz(board, path, {'user' => user})
#         end
#       elsif file_type == 'obf'
#         OBF::CoughDrop.to_obf(board, path)
#       elsif file_type == 'pdf'
#         OBF::CoughDrop.to_pdf(board, path, {'user' => user, 'packet' => (include == 'all')})
#       end
#     end
#     OBF::Utils.update_current_progress(0.9, :uploading_file)
#     url = Uploader.remote_upload(remote_path, path, content_type)
#     raise "File not uploaded" unless url
#     File.unlink(path) if File.exist?(path)
#     return url
#   end
  
#   def self.remote_to_boards(user, url)
#     result = []
#     OBF::Utils.update_current_progress(0.1, :downloading_file)
#     response = Typhoeus.get(url)
#     file = Tempfile.new('stash')
#     file.binmode
#     file.write response.body
#     file.close
#     OBF::Utils.update_current_progress(0.2, :processing_file)
#     OBF::Utils.as_progress_percent(0.2, 1.0) do
#       if url.match(/\.obz$/) || response.headers['Content-Type'] == 'application/obz'
#         boards = OBF::CoughDrop.from_obz(file.path, {'user' => user})
#         result = boards
#       elsif url.match(/\.obf$/) || response.headers['Content-Type'] == 'application/obf'
#         board = OBF::CoughDrop.from_obf(file.path, {'user' => user})
#         result = [board]
#       else
#         raise "Unrecognized file type: #{response.headers['Content-Type']}"
#       end
#       file.unlink
#     end
#     return result
#   end
  
  def self.get_url(url)
    return nil unless url
    res = Typhoeus.get(URI.escape(url))
    extension = ""
    type = MIME::Types[res.headers['Content-Type']]
    type = type && type[0]
    extension = ("." + type.preferred_extension) if type && type.extensions && type.extensions.length > 0
    {
      'content_type' => res.headers['Content-Type'],
      'data' => res.body,
      'extension' => extension
    }
  end
  
  def self.image_raw(url)
    image = get_url(url)
    return nil unless image
    image
  end
  
  def self.image_base64(url)
    image = get_url(url)
    return nil unless image
    str = "data:" + image['content_type']
    str += ";base64," + Base64.strict_encode64(image['data'])
    str
  end
  
  def self.save_image(image, zipper=nil)
    if image['data']
      if !image['content_type']
        image['content_type'] = image['data'].split(/;/)[0].split(/:/)[1]
      end
    elsif image['path'] && zipper
      image['raw_data'] = zipper.read(image['path'])
      if !image['content_type']
        types = MIME::Types.type_for(image['path'])
        image['content_type'] = types[0] && types[0].to_s
      end
    elsif image['url']
      url_data = get_url(image['url'])
      image['raw_data'] = url_data['data']
      image['content_type'] = url_data['content_type']
    elsif image['symbol']
      # not supported
    end
    type = MIME::Types[image['content_type']]
    type = type && type[0]
    extension = type && ("." + type.extensions.first)
    file = Tempfile.new(["image_stash", extension.to_s])
    file.binmode
    if image['data']
      str = Base64.strict_decode64(image['data'].split(/\,/, 2)[1])
      file.write str
    elsif image['raw_data']
      file.write image['raw_data']
    else
      raise "uh-oh"
    end
    file.close
    `convert #{file.path} -density 1200 -resize 300x300 -background none -gravity center -extent 300x300 #{file.path}.png`
    "#{file.path}.png"
  end
  
  def self.sound_raw(url)
    sound = get_url(url)
    return nil unless sound
    sound
  end
  
  def self.sound_base64(url)
    sound = get_url(url)
    return nil unless sound
    str = "data:" + sound['content_type']
    str += ";base64," + Base64.strict_encode64(sound['data'])
    str
  end
  
  def self.obf_shell
    {
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
    }
  end
  
  def self.parse_obf(obj)
    json = obj
    if obj.is_a?(String)
      json = JSON.parse(obj)
    end
    ['images', 'sounds', 'buttons'].each do |key|
      json["#{key}_hash"] = json[key]
      if json[key].is_a?(Array)
        hash = {}
        json[key].each do |item|
          hash[item['id']] = item
        end
        json["#{key}_hash"] = hash
      else
        array = []
        json["#{key}_hash"].each do |id, item|
          item['id'] ||= id
          array << item
        end
        json[key] = array
      end
    end
    json
  end
  
  def self.parse_license(pre_license)
    pre_license = {} unless pre_license.is_a?(Hash)
    license = {}
    ['type', 'copyright_notice_url', 'source_url', 'author_name', 'author_url', 'author_email', 'uneditable'].each do |attr|
      license[attr] = pre_license[attr] if pre_license[attr] != nil
    end
    license['type'] ||= 'private'
    license['copyright_notice_url'] ||= license['copyright_notice_link'] if license.key?('copyright_notice_link')
    license['source_url'] ||= license['source_link'] if license.key?('source_link')
    license['author_url'] ||= license['author_link'] if license.key?('author_link')
    license
  end
  
  def self.parse_grid(pre_grid)
    pre_grid ||= {}
    grid = {
      'rows' => pre_grid['rows'] || 1,
      'columns' => pre_grid['columns'] || 1,
      'order' => pre_grid['order'] || [[nil]]
    }
    # TODO: parse order better
    grid
  end
  
  def self.temp_path(*args)
    file = Tempfile.new(*args)
    res = file.path
    file.unlink
    res
  end
  
  class Zipper
    def initialize(zipfile)
      @zipfile = zipfile
    end
    
    def add(path, contents)
      @zipfile.get_output_stream(path) {|os| os.write contents }
    end
    
    def read(path)
      entry = @zipfile.glob(path).first
      entry ? entry.get_input_stream.read : nil
    end
  end
  
  def self.load_zip(path, &block)
    require 'zip'

    Zip::File.open(path) do |zipfile|
      block.call(Zipper.new(zipfile))
    end
  end
  
  def self.build_zip(dest_path=nil, &block)
    require 'zip'
    
    if !dest_path
      dest_path = OBF::Utils.temp_path(['archive', '.obz'])
    end
    Zip::File.open(dest_path, Zip::File::CREATE) do |zipfile|
      block.call(Zipper.new(zipfile))
    end
  end
  
  def self.update_current_progress(*args)
    if Object.const_defined?('Progress')
      Progress.update_current_progress(*args)
    end
  end
  
  def self.as_progress_percent(a, b, &block)
    if Object.const_defined?('Progress')
      Progress.as_percent(a, b, &block)
    else
      block.call
    end
  end
end
