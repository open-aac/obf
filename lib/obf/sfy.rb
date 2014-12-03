module OBF::Sfy
  def self.to_external(path)
    boards = []
    images = []
    sounds = []
    
    plist = CFPropertyList::List.new(:file => path)
    data = CFPropertyList.native_types(plist.value)
    
    top = data['$top']['root']
    list = data['$objects'][top]
    
    items = {
      'strings' => {},
      'buttons' => []
    }
    board_ids = []
    images = []
    data['$objects'].each_with_index do |item, idx|
      if item.is_a?(String)
        items['strings'][idx] = item
      elsif item.is_a?(Hash) && item['mScreen']
        item['word'] = data['$objects'][item['wordKey']] if item['wordKey']
        item['symbol'] = data['$objects'][item['imageName']] if item['imageName']
        board_ids[item['mScreen']] = true
        items['buttons'] << item
      else
#        puts item.to_json
      end
    end
    
    image_counter = 0
    board_ids.each_with_index do |present, idx|
      if present
        name = "HOME" 
        if idx > 0
          if boards[0]
            name = boards[0]['buttons'][idx - 1]['label']
          else
            name = "Screen #{idx}"
          end
        end
        
        raw_buttons = items['buttons'].select{|b| b['mScreen'] == idx }
        buttons = []
        rows = 0
        columns = 0
        raw_buttons.each do |b|
          rows = [rows, b['mRow']].max
          columns = [columns, b['mColumn']].max
        end
        rows += 1
        columns += 1
        grid = {
          'rows' => rows,
          'columns' => columns,
          'order' => []
        }
        button_counter = 0
        rows.times do |i|
          grid['order'][i] = []
          columns.times do |j|
            grid['order'][i][j] = nil
            raw_button = raw_buttons.detect{|b| b['mRow'] == i && b['mColumn'] == j }
            colors = {
              0 => 'rgb(255, 255, 255)',  # white
              1 => 'rgb(255, 0, 0)',      # red
              3 => 'rgb(255, 112, 156)',  # red pink
              2 => 'rgb(255, 115, 222)',  # pinky purple
              4 => 'rgb(250, 196, 140)',  # light red-orange
              5 => 'rgb(255, 196, 87)',   # orange
              6 => 'rgb(255, 234, 117)',  # yellow
              7 => 'rgb(255, 241, 92)',   # yellowy
              8 => 'rgb(252, 242, 134)',  # light yellow
              9 => 'rgb(82, 209, 86)',    # dark green
              10 => 'rgb(149, 189, 42)',  # navy green
              11 => 'rgb(161, 245, 113)', # green
              12 => 'rgb(196, 252, 141)', # pale green
              13 => 'rgb(94, 207, 255)',  # strong blue
              14 => 'rgb(148, 223, 255)', # happy blue
              15 => 'rgb(176, 223, 255)', # bluey
              16 => 'rgb(194, 241, 255)', # light blue
              17 => 'rgb(118, 152, 199)', # dark purple
              18 => 'rgb(208, 190, 232)', # light purple
              19 => 'rgb(153, 79, 0)',    # brown
              20 => 'rgb(0, 109, 235)',   # dark blue
              21 => 'rgb(0, 0, 0)',       # black
              22 => 'rgb(161, 161, 161)', # gray
              23 => 'rgb(255, 108, 59)',  # dark orange
            }
            if raw_button
              image_id = nil
              if raw_button['symbol']
                # TODO: what's the difference in name between provided symbols and user images?
                if raw_button['symbol'].match(/-/)
                  # probably a user-defined symbol
                else
                  images << {
                    'id' => image_counter,
                    'symbol' => {
                      'set' => 'sfy',
                      'name' => raw_button['symbol']
                    }
                  }
                  image_id = image_counter
                  image_counter += 1
                end
              end
              button = {
                'id' => button_counter,
                'label' => raw_button['word'],
                'background_color' => colors[raw_button['backgroundColorID']],
                'image_id' => image_id,
                'hidden' => !raw_button['isOpen'],
                'ext_sfy_isLinked' => raw_button['isLinked'],
                'ext_sfy_isProtected' => raw_button['isProtected'],
                'ext_sfy_backgroundColorID' => raw_button['backgroundColorID']
              }
              if raw_button['customLabel'] && data['$objects'][raw_button['customLabel']] && data['$objects'][raw_button['customLabel']] != ""
                button['vocalization'] = button['label']
                button['label'] = data['$objects'][raw_button['customLabel']]
              end
              if idx == 0 && raw_button['isLinked'] && board_ids[button_counter + 1]
                button['load_board'] = {
                  'id' => (button_counter + 1).to_s
                }
              end
              grid['order'][i][j] = button['id']
              buttons << button
            end
            button_counter += 1
          end
        end
        board = {
          'id' => idx.to_s,
          'name' => name,
          'buttons' => buttons,
          'grid' => grid,
          'ext_sfy_screen' => idx
        }
        boards << board
      end
    end
    return {
      'boards' => boards,
      'images' => images,
      'sounds' => []
    }
  end
end