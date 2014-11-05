module OBF::Picto4me
  def self.to_external(zip_path)
    boards = []
    images = []
    sounds = []
    OBF::Utils.load_zip(zip_path) do |zipper|
      json = JSON.parse(zipper.read('*.js'))
      locale = json['locale']
      json['sheets'].each_with_index do |sheet, idx|
        board = OBF::Utils.obf_shell
        board['id'] = idx.to_s
        board['locale'] = locale
        board['name'] = sheet['title']['text']
        board['ext_picto4me_title'] = sheet['title']
        board['ext_picto4me_cellsize'] = sheet['cellsize']
        board['ext_picto4me_pictoOverrule'] = sheet['pictoOverrule']
        board['ext_picto4me_showPictoTitles'] = sheet['showPictoTitles']
        board['ext_picto4me_pictoBorder'] = sheet['pictoBorder']
        grid = []
        sheet['rows'].times do 
          grid << [nil] * sheet['columns']
        end
        board['grid'] = {
          'rows' => sheet['rows'],
          'columns' => sheet['columns'],
          'order' => grid
        }
        sheet['pictos'].each_with_index do |picto, jdx|
          next unless picto
          button = {}
          button['id'] = board['id'] + ":" + picto['id']
          button['label'] = picto['title']['text']
          button['vocalization'] = picto['description']['text']
          button['border_color'] = picto['borderColor'] unless picto['borderColor'] == 'transparent'
          button['background_color'] = picto['bgColor'] unless picto['bgColor'] == 'transparent'
          button['ext_picto4me_lang'] = picto['lang']
          button['ext_picto4me_description'] = picto['description']
          button['ext_picto4me_title'] = picto['title']
          button['ext_picto4me_overlay'] = picto['overlay']
          button['ext_picto4me_source'] = picto['source']
          button['ext_picto4me_key'] = picto['key']
          button['ext_picto4me_categories'] = picto['categories']
          button['ext_picto4me_size'] = picto['size']
          
          if picto['imageurl']
            image = {}
            image['id'] = 'img:' + button['id']
            
            attrs = zipper.read_as_data(picto['imageurl'][1..-1])
            raise "didn't work" unless attrs['data']
            image['data'] = attrs['data']
            image['width'] = attrs['width']
            image['height'] = attrs['height']
            image['content_type'] = attrs['content_type']

            images << image
            button['image_id'] = image['id']
          end
          if picto['soundurl']
            sound = {}
            sound['id'] = 'snd:' + button['id']
            
            attrs = zipper.read_as_data(picto['soundurl'][1..-1])
            raise "didn't work" unless attrs['data']
            sound['data'] = attrs['data']
            sound['content_type'] = attrs['content_type']

            sounds << sound
            button['sound_id'] = sound['id']
          end
          if picto['link'] && json['sheets'][picto['link'].to_i]
            button['load_board'] = {'id' => picto['link']}
          end
          board['buttons'] << button
          row = (jdx / sheet['columns']).floor.to_i
          col = jdx % sheet['columns']
          board['grid']['order'][row][col] = button['id']
        end
        boards << board
      end
    end
    images.uniq!
    sounds.uniq!
    if boards.length == 1
      board = boards[0]
      board['images'] = images
      board['sounds'] = sounds
      return board
    else
      return {
        'boards' => boards,
        'images' => images,
        'sounds' => sounds
      }
    end
  end
end