module OBF::External
  def self.to_obf(hash, dest_path, path_hash=nil)
    if hash['boards']
      old_hash = hash
      hash = old_hash['boards'][0]
      hash['images'] = old_hash['images'] || []
      hash['sounds'] = old_hash['sounds'] || []
      path_hash = nil
    end
    
    res = OBF::Utils.obf_shell
    res['id'] = hash['id']
    res['locale'] = hash['locale'] || 'en'
    res['format'] = OBF::OBF::FORMAT
    res['name'] = hash['name']
    res['default_layout'] = hash['default_layout'] || 'landscape'
    res['background'] = hash['background']
    res['url'] = hash['url']
    res['data_url'] = hash['data_url']

    res['default_locale'] = hash['default_locale'] if hash['default_locale']
    res['label_locale'] = hash['label_locale'] if hash['label_locale']
    res['vocalization_locale'] = hash['vocalization_locale'] if hash['vocalization_locale']
    
    res['description_html'] = hash['description_html']
    res['protected_content_user_identifier'] = hash['protected_content_user_identifier'] if hash['protected_content_user_identifier']
    res['license'] = OBF::Utils.parse_license(hash['license'])
    hash.each do |key, val|
      if key && key.match(/^ext_/)
        res[key] = val
      end
    end
    grid = []
    
    images = []
    sounds = []
    
    res['buttons'] = []
    buttons = hash['buttons'] #board.settings['buttons']
    button_count = buttons.length
    
    buttons.each_with_index do |original_button, idx|
      button = {
        'id' => original_button['id'],
        'label' => original_button['label'],
        'vocalization' => original_button['vocalization'],
        'action' => original_button['action'],
        'actions' => original_button['actions'],
        'left' => original_button['left'],
        'top' => original_button['top'],
        'width' => original_button['width'],
        'height' => original_button['height'],
        'border_color' => OBF::Utils.fix_color(original_button['border_color'] || "#aaa", 'rgb'),
        'background_color' => OBF::Utils.fix_color(original_button['background_color'] || "#fff", 'rgb')
      }
      if original_button['load_board']
        button['load_board'] = {
          'id' => original_button['load_board']['id'],
          'url' => original_button['load_board']['url'],
          'data_url' => original_button['load_board']['data_url']
        }
        if path_hash && path_hash['included_boards'] && path_hash['included_boards'][original_button['load_board']['id']]
          button['load_board']['path'] = "board_#{original_button['load_board']['id']}.obf"
        end
      end
      if original_button['translations']
        original_button['translations'].each do |loc, hash|
          next unless hash.is_a?(Hash)
          button['translations'] ||= {}
          button['translations'][loc] ||= {}
          button['translations'][loc]['label'] = hash['label'].to_s if hash['label']
          button['translations'][loc]['vocalization'] = hash['vocalization'].to_s if hash['vocalization']
          (hash['inflections'] || {}).each do |key, val|
            if key.match(/^ext_/)
              button['translations'][loc]['inflections'] ||= {}
              button['translations'][loc]['inflections'][key] = val
            else
              button['translations'][loc]['inflections'] ||= {}
              button['translations'][loc]['inflections'][key] = val.to_s
            end
          end
          hash.keys.each do |key|
            button['translations'][loc][key] = hash[key] if key.to_s.match(/^ext_/)
          end
        end
      end
      if original_button['hidden']
        button['hidden'] = original_button['hidden']
      end
      if original_button['url']
        button['url'] = original_button['url']
      end
      original_button.each do|key, val|
        if key.match(/^ext_/)
          button[key] = val
        end
      end

      if original_button['image_id'] && hash['images']
        image = hash['images'].detect{|i| i['id'] == original_button['image_id']}
        if image
          images << image
          button['image_id'] = image['id']
        end
      end
      if original_button['sound_id']
        sound = hash['sounds'].detect{|s| s['id'] == original_button['sound_id']}
        if sound
          sounds << sound
          button['sound_id'] = sound['id']
        end
      end
      res['buttons'] << trim_empties(button)
      OBF::Utils.update_current_progress(idx.to_f / button_count.to_f)
    end

    images.each do |original_image|
      image = {
        'id' => original_image['id'],
        'width' => original_image['width'],
        'height' => original_image['height'],
        'license' => OBF::Utils.parse_license(original_image['license']),
        'url' => original_image['url'],
        'data' => original_image['data'],
        'data_url' => original_image['data_url'],
        'content_type' => original_image['content_type']
      }
      if !path_hash
        image['data'] ||= OBF::Utils.image_base64(image['url']) if image['url']
        if image['data'] && (!image['content_type'] || !image['width'] || !image['height'])
          attrs = OBF::Utils.image_attrs(image['data'])
          image['content_type'] ||= attrs['content_type']
          image['width'] ||= attrs['width']
          image['height'] ||= attrs['height']
        end
      else
        if path_hash['images'] && path_hash['images'][image['id']]
          image['path'] = path_hash['images'][image['id']]['path']
          image['content_type'] ||= path_hash['images'][image['id']]['content_type']
          image['width'] ||= path_hash['images'][image['id']]['width']
          image['height'] ||= path_hash['images'][image['id']]['height']
        else
          image_fetch = OBF::Utils.image_raw(image['data'] || image['url'])
          if image_fetch
            if !image['content_type'] || !image['width'] || !image['height']
              attrs = OBF::Utils.image_attrs(image_fetch['data'])
              image['content_type'] ||= image_fetch['content_type'] || attrs['content_type']
              image['width'] ||= attrs['width']
              image['height'] ||= attrs['height']
            end
            zip_path = "images/image_#{image['id']}#{image_fetch['extension']}"
            path_hash['images'] ||= {}
            path_hash['images'][image['id']] = {
              'path' => zip_path,
              'content_type' => image['content_type'],
              'width' => image['width'],
              'height' => image['height']
            }
            path_hash['zip'].add(zip_path, image_fetch['data'])
            image['path'] = zip_path
          end
        end
      end
      res['images'] << trim_empties(image)
    end
    
    sounds.each do |original_sound|
      sound = {
        'id' => original_sound['id'],
        'duration' => original_sound['duration'],
        'license' => OBF::Utils.parse_license(original_sound['license']),
        'url' => original_sound['url'],
        'data' => original_sound['data'],
        'data_url' => original_sound['data_url'],
        'content_type' => original_sound['content_type']
      }
      if !path_hash
        sound['data'] = OBF::Utils.sound_base64(sound['url']) if sound['url']
      else
        if path_hash['sounds'] && path_hash['sounds'][sound['id']]
          sound['path'] = path_hash['sounds'][sound['id']]['path']
        else
          sound_fetch = OBF::Utils.sound_raw(sound['url'] || sound['data'])
          if sound_fetch
            zip_path = "sounds/sound_#{sound['id']}#{sound_fetch['extension']}"
            path_hash['sounds'] ||= {}
            path_hash['sounds'][sound['id']] = {
              'path' => zip_path
            }
            path_hash['zip'].add(zip_path, sound_fetch['data'])
            sound['path'] = zip_path
          end
        end
        sound['path'] = zip_path
      end
      
      res['sounds'] << trim_empties(sound)
    end

    res['grid'] = OBF::Utils.parse_grid(hash['grid']) # TODO: more robust parsing here
    if path_hash
      zip_path = "board_#{res['id']}.obf"
      path_hash['boards'] ||= {}
      path_hash['boards'][res['id']] = {
        'path' => zip_path
      }
      path_hash['zip'].add(zip_path, JSON.pretty_generate(res))
    else
      File.open(dest_path, 'w') {|f| f.write(JSON.pretty_generate(res)) }
    end
    return dest_path
  end
  
  def self.trim_empties(hash)
    new_hash = {}
    hash.each do |key, val|
      new_hash[key] = val if val != nil
    end
    new_hash
  end
  
  def self.from_obf(obf_json_or_path, opts)
    opts ||= {}
    obj = obf_json_or_path
    if obj.is_a?(String)
      obj = OBF::Utils.parse_obf(File.read(obf_json_or_path), opts)
    else
      obj = OBF::Utils.parse_obf(obf_json_or_path, opts)
    end
    
    ['images', 'sounds'].each do |type|
      (obj[type] || []).each do |item|
        if !item['data'] && item['path'] && opts['zipper']
          content_type = item['content_type']
          data = opts['zipper'].read(item['path'])
          str = "data:" + content_type
          str += ";base64," + Base64.strict_encode64(data)
          item['data'] = str
        end
        if item['path']
          opts[type] ||= {} 
          opts[type][item['path']] ||= item
        end
      end
    end
    
    obj['license'] = OBF::Utils.parse_license(obj['license'])
    obj
  end
  
  def self.to_obz(content, dest_path, opts)
    if content['id']
      old_content = content
      content = {
        'boards' => [old_content],
        'images' => old_content['images'] || [],
        'sounds' => old_content['sounds'] || []
      }
    end
    
    paths = {}
    boards = content['boards']
    content['images'] ||= boards.map{|b| b['images'] }.flatten.uniq
    content['sounds'] ||= boards.map{|b| b['sounds'] }.flatten.uniq
    root_board = boards[0]
    OBF::Utils.build_zip(dest_path) do |zipper|
      paths['zip'] = zipper
      paths['included_boards'] = {}
      boards.each do |b|
        paths['included_boards'][b['id']] = b
      end
      boards.each do |b|
        b = paths['included_boards'][b['id']]
        if b
          b['images'] = content['images'] || []
          b['sounds'] = content['sounds'] || []
          to_obf(b, nil, paths)
        end
      end
      manifest = {
        'format' => OBF::OBF::FORMAT,
        'root' => paths['boards'][root_board['id']]['path'],
        'paths' => {}
      }
      ['images', 'sounds', 'boards'].each do |type|
        manifest['paths'][type] = {}
        (paths[type] || {}).each do |id, opts|
          manifest['paths'][type][id] = opts['path']
        end
      end
      
      zipper.add('manifest.json', JSON.pretty_generate(manifest))
    end
    return dest_path
  end
  
  def self.from_obz(obz_path, opts)
    boards = []
    images = []
    sounds = []
    OBF::Utils.load_zip(obz_path) do |zipper|
      obf_opts = {'zipper' => zipper, 'images' => {}, 'sounds' => {}, 'boards' => {}}
      manifest = JSON.parse(zipper.read('manifest.json'))
      obf_opts['manifest'] = manifest
      root = manifest['root']
      board = OBF::Utils.parse_obf(zipper.read(root), obf_opts)
      board['path'] = root
      unvisited_boards = [board]
      visited_boards = []
      while unvisited_boards.length > 0
        board_object = unvisited_boards.shift
        board_object['id'] ||= rand(9999).to_s + Time.now.to_i.to_s
        visited_boards << board_object

        board_object['buttons'].each do |button|
          if button['load_board']
            all_boards = visited_boards + unvisited_boards
            if all_boards.none?{|b| b['id'] == button['load_board']['id'] || b['path'] == button['load_board']['path'] }
              path = button['load_board']['path'] || (manifest['paths'] && manifest['paths']['boards'] && manifest['paths']['boards'][button['load_board']['id']])
              if path
                b = OBF::Utils.parse_obf(zipper.read(path), obf_opts)
                b['path'] = path
                button['load_board']['id'] = b['id']
                unvisited_boards << b
              end
            end
          end
        end
      end
      visited_boards.each do |board_object|
        res = from_obf(board_object, obf_opts)
        images += res['images'] || []
        sounds += res['sounds'] || []
        boards << res
      end
    end
    images.uniq!
    sounds.uniq!
    raise "image ids must be present and unique" unless images.map{|i| i['id'] }.uniq.length == images.length
    raise "sound ids must be present and unique" unless sounds.map{|i| i['id'] }.uniq.length == sounds.length
    # TODO: try to fix the problem where multiple images or sounds have the same id --
    # this involves reaching in and updating image and sound references on generated boards..
    res = {
      'boards' => boards,
      'images' => images,
      'sounds' => sounds
    }
    res
  end
  
  def self.to_pdf(board, dest_path, opts)
    if board && board['boards']
      opts['packet'] = true
    end
    tmp_path = OBF::Utils.temp_path("stash")
    if opts['packet']
      OBF::Utils.as_progress_percent(0, 0.3) do
        OBF::External.to_obz(board, tmp_path, opts)  
      end
      OBF::Utils.as_progress_percent(0.3, 1.0) do
        OBF::OBZ.to_pdf(tmp_path, dest_path, opts)
      end
    else
      OBF::Utils.as_progress_percent(0, 0.5) do
        self.to_obf(board, tmp_path)  
      end
      OBF::Utils.as_progress_percent(0.5, 1.0) do
        OBF::OBF.to_pdf(tmp_path, dest_path, opts)
      end
    end
    File.unlink(tmp_path) if File.exist?(tmp_path)
    dest_path
  end
  
  def self.to_png(board, dest_path, opts)
    tmp_path = OBF::Utils.temp_path("stash")
    OBF::Utils.as_progress_percent(0, 0.5) do
      self.to_pdf(board, tmp_path, opts)
    end
    OBF::Utils.as_progress_percent(0.5, 1.0) do
      OBF::PDF.to_png(tmp_path, dest_path)
    end
    File.unlink(tmp_path) if File.exist?(tmp_path)
    dest_path
  end
  
  class StructureError < StandardError; end
end