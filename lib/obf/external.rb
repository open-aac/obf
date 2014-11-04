module OBF::External
  def self.to_obf(hash, dest_path, path_hash=nil)
    res = OBF::Utils.obf_shell
    res['id'] = hash['id'] #board.global_id
    res['name'] = hash['name'] #board.settings['name']
    res['default_layout'] = hash['default_layout'] || 'landscape' #'landscape'
    res['url'] = hash['url'] #"#{JsonApi::Json.current_host}/#{board.key}"
    res['data_url'] = hash['data_url'] #"#{JsonApi::Json.current_host}/api/v1/boards/#{board.key}"
    res['description_html'] = hash['description_html'] #board.settings['description']
    res['license'] = OBF::Utils.parse_license(hash['license']) #board.settings['license'])
    res['settings'] = {
      'private' => !!(hash['settings'] && hash['settings']['private']), #!board.public,
      'key' => hash['key'] #board.key.split(/\//, 2)[1]
    }
    grid = []
    
    res['images'] = []
    (hash['images'] || []).each do |original_image|
      image = {
        'id' => original_image['id'],
        'width' => original_image['width'],
        'height' => original_image['height'],
        'license' => OBF::Utils.parse_license(original_image['license']),
        'url' => original_image['url'],
        'data_url' => original_image['data_url'],
        'content_type' => original_image['content_type']
      }
      if !path_hash
        image['data'] = OBF::Utils.image_base64(image['url'])
      else
        if path_hash['images'] && path_hash['images'][image['id']]
          image['path'] = path_hash['images'][image['id']]['path']
        else
          image_fetch = OBF::Utils.image_raw(image['url'])
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
#         image = board.button_images.detect{|i| i.global_id == original_button['image_id'] }
#         image = {
#           'id' => image.global_id,
#           'width' => image.settings['width'],
#           'height' => image.settings['height'],
#           'license' => OBF::Utils.parse_license(image.settings['license']),
#           'url' => image.url,
#           'data_url' => "#{JsonApi::Json.current_host}/api/v1/images/#{image.global_id}",
#           'content_type' => image.settings['content_type']
#         }
    end
    
    res['sounds'] = []
    (hash['sounds'] || []).each do |original_sound|
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
          sound_fetch = OBF::Utils.sound_raw(sound['url'])
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
      
#         sound = board.button_sounds.detect{|i| i.global_id == original_button['sound_id'] }
#         sound = {
#           'id' => sound.global_id,
#           'duration' => sound.settings['duration'],
#           'license' => OBF::Utils.parse_license(sound.settings['license']),
#           'url' => sound.url,
#           'data_url' => "#{JsonApi::Json.current_host}/api/v1/sounds/#{sound.global_id}",
#           'content_type' => sound.settings['content_type']
#         }
    end
    
    res['buttons'] = []
    buttons = hash['buttons'] #board.settings['buttons']
    button_count = buttons.length
    
    buttons.each_with_index do |original_button, idx|
      button = {
        'id' => original_button['id'],
        'label' => original_button['label'],
        'vocalization' => original_button['vocalization'],
        'left' => original_button['left'],
        'top' => original_button['top'],
        'width' => original_button['width'],
        'height' => original_button['height'],
        'border_color' => original_button['border_color'] || "#aaa",
        'background_color' => original_button['background_color'] || "#fff"
      }
      if original_button['load_board']
        button['load_board'] = {
          'id' => original_button['load_board']['id'],
          'url' => original_button['load_board']['url'], #"#{JsonApi::Json.current_host}/#{original_button['load_board']['key']}",
          'data_url' => original_button['load_board']['data_url'] #"#{JsonApi::Json.current_host}/api/v1/boards/#{original_button['load_board']['key']}"
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
#       if original_button['apps']
#         button['ext_coughdrop_apps'] = original_button['apps']
#         if original_button['apps']['web'] && original_button['apps']['web']['launch_url']
#           button['url'] = original_button['apps']['web']['launch_url']
#         end
#       end
      if original_button['image_id'] && hash['images']
        image = res['images'].detect{|i| i['id'] == original_button['image_id']}
        if image
          button['image_id'] = image['id']
        end
      end
      if original_button['sound_id']
        sound = res['sounds'].detect{|s| s['id'] == original_button['sound_id']}
        if sound
          button['sound_id'] = sound['id']
        end
      end
      res['buttons'] << button
      OBF::Utils.update_current_progress(idx.to_f / button_count.to_f)
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
      obj[type].each do |item|
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
      end
    end
    
    obj['license'] = OBF::Utils.parse_license(obj['license'])
    obj

#     raise "user required" unless opts['user']
#     raise "missing id" unless obj['id']
# 
#     hashes = {}
#     [['images_hash', ButtonImage], ['sounds_hash', ButtonSound]].each do |list, klass|
#       obj[list].each do |id, item|
#         record = nil
#         unique_id = obj['id'] + "_" + item['id'].to_s
#         if opts[list] && opts[list][unique_id]
#           record = klass.find_by_global_id(opts[list][unique_id])
#         elsif item['data']
#           record = klass.create(:user => opts['user'])
#           item['ref_url'] = item['data']
#         elsif item['path'] && opts['zipper']
#           content_type = item['content_type']
#           data = opts['zipper'].read(item['path'])
#           str = "data:" + content_type
#           str += ";base64," + Base64.strict_encode64(data)
#           record = klass.create(:user => opts['user'])
#           item['ref_url'] = str
#         elsif item['url']
#           record = klass.create(:user => opts['user'])
#           item['ref_url'] = item['url']
#         end
#         if record
#           item.delete('data')
#           item.delete('url')
#           record.process(item)
#           record.upload_to_remote(item['ref_url']) if item['ref_url']
#           opts[list] ||= {}
#           opts[list][unique_id] = record.global_id
#           hashes[item['id']] = record.global_id
#         end
#       end
#     end

#     params = {}
#     non_user_params = {'user' => opts['user']}
#     params['name'] = obj['name']
#     params['description'] = obj['description_html']
#     params['image_url'] = obj['image_url']
#     params['license'] = OBF::Utils.parse_license(obj['license'])
#     params['buttons'] = obj['buttons'].map do |button|
#       new_button = {
#         'id' => button['id'],
#         'label' => button['label'],
#         'vocalization' => button['vocalization'],
#         'left' => button['left'],
#         'top' => button['top'],
#         'width' => button['width'],
#         'height' => button['height'],
#         'border_color' => button['border_color'],
#         'background_color' => button['background_color']
#       }
#       if button['image_id']
#         new_button['image_id'] = hashes[button['image_id']]
#       end
#       if button['sound_id']
#         new_button['sound_id'] = hashes[button['sound_id']]
#       end
#       if button['load_board'] 
#         if opts['boards'] && opts['boards'][button['load_board']['id']]
#           new_button['load_board'] = opts['boards'][button['load_board']['id']]
#         else
#           link = Board.find_by_path(button['load_board']['key'] || button['load_board']['id'])
#           if link
#             new_button['load_board'] = {
#               'id' => link.global_id,
#               'key' => link.key
#             }
#           end
#         end
#       elsif button['url']
#         if button['ext_coughdrop_apps']
#           new_button['apps'] = button['ext_coughdrop_apps']
#         else
#           new_button['url'] = button['url']
#         end
#       end
#       new_button
#     end
#     params['grid'] = obj['grid']
#     params['public'] = !(obj['settings'] && obj['settings']['private'])
#     non_user_params[:key] = (obj['settings'] && obj['settings']['key'])
#     board = nil
#     if opts['boards'] && opts['boards'][obj['id']]
#       board = Board.find_by_path(opts['boards'][obj['id']]['id']) || Board.find_by_path(opts['boards'][obj['id']]['key'])
#       board.process(params, non_user_params)
#     else
#       board = Board.process_new(params, non_user_params)
#       opts['boards'] ||= {}
#       opts['boards'][obj['id']] = {
#         'id' => board.global_id,
#         'key' => board.key
#       }
#     end
#     board
# 

  end
  
  def self.to_obz(boards, dest_path, opts)
    paths = {}
    root_board = boards[0]
    OBF::Utils.build_zip(dest_path) do |zipper|
      paths['zip'] = zipper
#       board.track_downstream_boards!
      paths['included_boards'] = {}
      boards.each do |b|
        paths['included_boards'][b['id']] = b
      end
      boards.each do |b|
        b = paths['included_boards'][b['id']]
        to_obf(b, nil, paths) if b
      end
#       board.settings['downstream_board_ids'].each do |id|
#         b = Board.find_by_path(id)
#         if b.allows?(opts['user'], 'view')
#           paths['included_boards'][id] = b
#         end
#       end
#       to_obf(board, nil, paths)
#       board.settings['downstream_board_ids'].each do |id|
#         b = paths['included_boards'][id]
#         to_obf(b, nil, paths) if b
#       end
      manifest = {
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
    result = []
    OBF::Utils.load_zip(obz_path) do |zipper|
      manifest = JSON.parse(zipper.read('manifest.json'))
      root = manifest['root']
      board = OBF::Utils.parse_obf(zipper.read(root))
      board['path'] = root
      unvisited_boards = [board]
      visited_boards = []
      obf_opts = {'zipper' => zipper, 'images' => {}, 'sounds' => {}, 'boards' => {}}
#      obf_opts = {'user' => opts['user'], 'zipper' => 'zipper', 'images' => {}, 'sounds' => {}, 'boards' => {}}
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
        result << from_obf(board_object, obf_opts)
      end
    end
    return result
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