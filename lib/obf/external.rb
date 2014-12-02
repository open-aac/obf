module OBF::External
  def self.to_obf(hash, dest_path, path_hash=nil)
    if hash['boards']
      old_hash = hash
      hash = old_hash['boards'][0]
      hash['images'] = content['images'] || []
      hash['sounds'] = content['sounds'] || []
      path_hash = nil
    end
    
    res = OBF::Utils.obf_shell
    res['id'] = hash['id']
    res['locale'] = hash['locale'] || 'en'
    res['format'] = 'open-board-0.1'
    res['name'] = hash['name']
    res['default_layout'] = hash['default_layout'] || 'landscape'
    res['url'] = hash['url']
    res['data_url'] = hash['data_url']
    res['description_html'] = hash['description_html']
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
        if path_hash && path_hash['included_boards'][original_button['load_board']['id']]
          button['load_board']['path'] = "board_#{original_button['load_board']['id']}.obf"
        end
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
      res['buttons'] << button
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
        image['data'] = OBF::Utils.image_base64(image['url'])
      else
        if path_hash['images'] && path_hash['images'][image['id']]
          image['path'] = path_hash['images'][image['id']]['path']
        else
          image_fetch = OBF::Utils.image_raw(image['url'] || image['data'])
          if image_fetch
            zip_path = "images/image_#{image['id']}#{image_fetch['extension']}"
            path_hash['images'] ||= {}
            path_hash['images'][image['id']] = {
              'path' => zip_path
            }
            path_hash['zip'].add(zip_path, image_fetch['data'])
            image['path'] = zip_path
          end
        end
      end
      res['images'] << image
    end
    
    sounds.each do |original_sound|
      sound = {
        'id' => original_sound['id'],
        'duration' => original_sound['duration'],
        'license' => OBF::Utils.parse_license(original_sound['license']),
        'url' => original_sound['url'],
        'data_url' => original_sound['data_url'],
        'content_type' => original_sound['content_type']
      }
      if !path_hash
        sound['data'] = OBF::Utils.sound_base64(sound['url'])
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
      
      res['sounds'] << sound
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
  
  def self.from_obf(obf_json_or_path, opts)
    obj = obf_json_or_path
    if obj.is_a?(String)
      obj = OBF::Utils.parse_obf(File.read(obf_json_or_path))
    else
      obj = OBF::Utils.parse_obf(obf_json_or_path)
    end
    
    ['images', 'sounds'].each do |type|
      (obj[type] || []).each do |item|
        item['data_or_url'] = item['data']
        if !item['data_or_url'] && item['path'] && opts['zipper']
          content_type = item['content_type']
          data = opts['zipper'].read(item['path'])
          str = "data:" + content_type
          str += ";base64," + Base64.strict_encode64(data)
          record = klass.create(:user => opts['user'])
          item['data_or_url'] = str
        end
        item['data_or_url'] ||= item['url']
        if item['path']
          opts[list] ||= {} 
          opts[list][item['path']] ||= item
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
        'format' => 'open-board-0.1',
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
      root = manifest['root']
      board = OBF::Utils.parse_obf(zipper.read(root))
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
              path = button['load_board']['path'] || manifest[button['load_board']['id']]
              b = OBF::Utils.parse_obf(zipper.read(path))
              b['path'] = path
              unvisited_boards << b
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
    return {
      'boards' => boards,
      'images' => images,
      'sounds' => sounds
    }
  end
  
  def self.to_pdf(board, dest_path, opts)
    tmp_path = OBF::Utils.temp_path("stash")
    if opts['packet']
      OBF::Utils.as_progress_percent(0, 0.3) do
        OBF::External.to_obz(board, tmp_path, opts)  
      end
      OBF::Utils.as_progress_percent(0.3, 1.0) do
        OBF::OBZ.to_pdf(tmp_path, dest_path)
      end
    else
      OBF::Utils.as_progress_percent(0, 0.5) do
        self.to_obf(board, tmp_path)  
      end
      OBF::Utils.as_progress_percent(0.5, 1.0) do
        OBF::OBF.to_pdf(tmp_path, dest_path)
      end
    end
    File.unlink(tmp_path) if File.exist?(tmp_path)
    dest_path
  end
  
  def self.to_png(board, dest_path)
    tmp_path = OBF::Utils.temp_path("stash")
    OBF::Utils.as_progress_percent(0, 0.5) do
      self.to_pdf(board, tmp_path)
    end
    OBF::Utils.as_progress_percent(0.5, 1.0) do
      OBF::PDF.to_png(tmp_path, dest_path)
    end
    File.unlink(tmp_path) if File.exist?(tmp_path)
    dest_path
  end
end