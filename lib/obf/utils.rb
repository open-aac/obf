require 'cfpropertylist'
module OBF::Utils
  def self.get_url(url)
    return nil unless url
    content_type = nil
    data = nil
    if url.match(/^data:/)
      content_type = url.split(/;/)[0].split(/:/)[1]
      data = Base64.strict_decode64(url.split(/\,/, 2)[1])
    else
      res = Typhoeus.get(URI.escape(url))
      content_type = res.headers['Content-Type']
      data = res.body
    end
    type = MIME::Types[content_type]
    type = type && type[0]
    extension = ""
    if type.respond_to?(:preferred_extension)
      extension = ("." + type.preferred_extension) if type.preferred_extension
    elsif type.respond_to?(:extensions)
      extension = ("." + type.extensions[0]) if type && type.extensions && type.extensions.length > 0
    end
    res = {
      'content_type' => content_type,
      'data' => data,
      'extension' => extension
    }
    res
  end
  
  def self.identify_file(path)
    name = File.basename(path) rescue nil
    if name.match(/\.obf$/)
      return :obf
    elsif name.match(/\.obz$/)
      return :obz
    elsif name.match(/\.avz$/)
      return :avz
    else
      json = JSON.parse(File.read(path)) rescue nil
      if json
        if json.is_a?(Hash)
          if json['format'] && json['format'].match(/^open-board-/)
            return :obf
          end
          return :json_not_obf
        else
          return :json_not_object
        end
      end
      
      begin
        plist = CFPropertyList::List.new(:file => path) rescue nil
        plist_data = CFPropertyList.native_types(plist.value) rescue nil
        if plist_data
          if plist_data['$objects'] && plist_data['$objects'].any?{|o| o['$classname'] == 'SYWord' }
            return :sfy
          end
          return :unknown
        end
      rescue CFFormatError => e
      end
      
      xml = Nokogiri::XML(File.open(path)) rescue nil
      if xml && xml.children.length > 0
        if xml.children[0].name == 'sensorygrid'
          return :sgrid
        end
        return :unknown
      end

      begin
        type = nil
        load_zip(path) do |zipper|
          if zipper.glob('manifest.json').length > 0
            json = JSON.parse(zipper.read('manifest.json')) rescue nil
            if json['root'] && json['format'] && json['format'].match(/^open-board-/)
              type = :obz
            end
          end
          if !type && zipper.glob('*.js').length > 0
            json = JSON.parse(zipper.read('*.js')) rescue nil
            if json['locale'] && json['sheets']
              type = :picto4me
            end
          end
        end
        return type if type
      rescue Zip::Error => e
      end
    end
    return :unknown
  end
  
  def self.image_raw(url)
    image = get_url(url)
    return nil unless image
    image
  end
  
  def self.image_base64(url)
    image = nil
    if url.match(/:\/\//)
      image = get_url(url)
    else
      types = MIME::Types.type_for(url)
      image = {
        'data' => File.read(url),
        'content_type' => types[0] && types[0].to_s
      }
      if !image['content_type']
        attrs = image_attrs(url)
        image['content_type'] ||= attrs['content_type']
      end
    end
    return nil unless image
    str = "data:" + image['content_type']
    str += ";base64," + Base64.strict_encode64(image['data'])
    str
  end
  
  def self.save_image(image, zipper=nil, background=nil)
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
    extension = nil
    if type.respond_to?(:preferred_extension)
      extension = type && ("." + type.preferred_extension)
    elsif type.respond_to?(:extensions)
      extension = type && ("." + type.extensions.first)
    end
    file = Tempfile.new(["image_stash", extension.to_s])
    file.binmode
    if image['data']
      str = Base64.strict_decode64(image['data'].split(/\,/, 2)[1])
      file.write str
    elsif image['raw_data']
      file.write image['raw_data']
    else
      file.close
      return nil
    end
    file.close
    if extension && ['image/jpeg', 'image/jpg', 'image/gif'].include?(image['content_type']) && image['width'] && image['width'] < 1000 && image['width'] == image['height']
      # png files need to be converted to make sure they don't have a transparent bg, or
      # else performance takes a huge hit.
      `cp #{file.path} #{file.path}.#{extension}`
      "#{file.path}.#{extension}"
    else
      # TODO: maybe convert to jpg instead of png?
      # see https://github.com/prawnpdf/prawn/issues/324
      # in that case, fill the image with a white background, perhaps?
      background ||= 'white'
      `convert #{file.path} -density 1200 -resize 200x200 -background "#{background}" -gravity center -extent 200x200 #{file.path}.jpg`
      "#{file.path}.jpg"
    end
  end
  
  def self.sound_raw(url)
    sound = get_url(url)
    return nil unless sound
    sound
  end
  
  def self.sound_base64(url)
    sound = nil
    if url.match(/:\/\//)
      sound = get_url(url)
    else
      types = MIME::Types.type_for(url)
      sound = {
        'data' => File.read(url),
        'content_type' => types[0] && types[0].to_s
      }
    end
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

  def self.fix_color(str, type='hex')
    lookup = str + "::" + type
    @@colors ||= {}
    return @@colors[lookup] if @@colors[lookup]
    path = File.dirname(File.dirname(__FILE__)) + '/tinycolor_convert.js'
    color = `node #{path} "#{str}" #{type}`.strip
    @@colors[lookup] = color
    color
  end
  
  def self.parse_obf(obj, opts=nil)
    opts ||= {}
    json = obj
    if obj.is_a?(String)
      json = JSON.parse(obj)
    end
    if opts['manifest']
      (json['buttons'] || []).each do |button|
        if button['image_id']
          # find image in list, if it has an id but no path, use the path from the manifest
          image = (json['images'] || []).detect{|i| i['id'] == button['image_id'] }
          if image && !image['path'] && !image['data'] && opts['manifest'] && opts['manifest']['paths'] && opts['manifest']['paths']['images'] && opts['manifest']['paths']['images'][button['image_id']]
            image['path'] = opts['manifest']['paths']['images'][button['image_id']]
          end
        end
        if button['sound_id']
          # find sound in list, if it has an id but no path, use the path from the manifest
          sound = (json['sounds'] || []).detect{|s| s['id'] == button['sound_id'] }
          if sound && !sound['path'] && !sound['data'] && opts['manifest'] && opts['manifest']['paths'] && opts['manifest']['paths']['sounds'] && opts['manifest']['paths']['sounds'][button['sound_id']]
            sound['path'] = opts['manifest']['paths']['sounds'][button['sound_id']]
          end
        end
      end
    end
    ['images', 'sounds', 'buttons'].each do |key|
      json["#{key}_hash"] = json[key]
      if json[key].is_a?(Array)
        hash = {}
        json[key].compact.each do |item|
          hash[item['id']] = item
        end
        json["#{key}_hash"] = hash
      elsif json["#{key}_hash"]
        array = []
        json["#{key}_hash"].each do |id, item|
          if item
            item['id'] ||= id
            array << item
          end
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
  
  def self.image_attrs(path, extension='')
    res = {}
    if path.match(/^data:/)
      res['content_type'] = path.split(/;/)[0].split(/:/)[1]
      raw = Base64.strict_decode64(path.split(/\,/, 2)[1])
      file = Tempfile.new(['file', extension])
      path = file.path
      file.binmode
      file.write raw
      file.close
    else
      is_file = File.exist?(path) rescue false
      if !is_file
        file = Tempfile.new(['file', extension])
        file.binmode
        file.write path
        path = file.path
        file.close
      end
    end
    data = `identify -verbose #{path}`
    data.split(/\n/).each do |line|
      pre, post = line.sub(/^\s+/, '').split(/:\s/, 2)
      if pre == 'Geometry'
        match = post.match(/(\d+)x(\d+)/)
        if match && match[1] && match[2]
          res['width'] = match[1].to_i
          res['height'] = match[2].to_i
        end
      elsif pre == 'Mime type'
        res['content_type'] = post
      end
    end
    if res['content_type'] && res['content_type'].match(/^image\/svg/)
      res['width'] ||= 300
      res['height'] ||= 300
    end
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
      entry = @zipfile.glob(path).first rescue nil
      entry ? entry.get_input_stream.read : nil
    end
    
    def glob(path)
      @zipfile.glob(path)
    end
    
    def all_files
      @zipfile.entries.select{|e| e.file? }.map{|e| e.to_s }
    end

    def read_as_data(path)
      attrs = {}
      raw = @zipfile.read(path)
      types = MIME::Types.type_for(path)
      attrs['content_type'] = types[0] && types[0].to_s
    
      str = "data:" + attrs['content_type']
      str += ";base64," + Base64.strict_encode64(raw)
      attrs['data'] = str
    
      if attrs['content_type'].match(/^image/)
        file = Tempfile.new('file')
        file.binmode
        file.write raw
        file.close
        more_attrs = OBF::Utils.image_attrs(file.path)
        attrs['content_type'] ||= more_attrs['content_type']
        attrs['width'] ||= more_attrs['width']
        attrs['height'] ||= more_attrs['height']
      end
      attrs
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
    if Object.const_defined?('Progress') && Progress.respond_to?(:update_current_progress)
      Progress.update_current_progress(*args)
    end
  end
  
  def self.as_progress_percent(a, b, &block)
    if Object.const_defined?('Progress') && Progress.respond_to?(:as_percent)
      Progress.as_percent(a, b, &block)
    else
      block.call
    end
  end
end
