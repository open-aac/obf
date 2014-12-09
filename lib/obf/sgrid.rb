module OBF::Sgrid
  EXT_PREFIX = 'ext_sgrid_'
  
  def self.html_at(elem, css)
    res = elem.css(css)[0]
    if res && res.inner_html && res.inner_html.length > 0
      res.inner_html
    else
      nil
    end
  end
  
  def self.to_external(path)
    xml = Nokogiri::XML(File.open(path))
    grid = xml.css('sensorygrid grid')[0]
    rows = html_at(grid, 'rows').to_i
    columns = html_at(grid, 'cols').to_i
    board = {
      'id' => 'sgrid'
    }
    ['selfclosing', 'titlebartext', 'customblockscan', 'predictionsource', 'oskcellratio', 'workspace_x', 'workspace_y', 'eyegazemonitor_x', 'eyegazemonitor_y'].each do |attr|
      res = html_at(grid, attr)
      board[EXT_PREFIX + attr] = res if res
    end
    if grid.css('background')[0]
      bg = grid.css('background')[0]
      board['ext_sgrid_background'] = {
        'style' => bg['style'],
        'backcolour' => html_at(bg, 'backcolour'),
        'backcolour2' => html_at(bg, 'backcolour2'),
        'picformat' => html_at(bg, 'picformat'),
        'tilepicture' => html_at(bg, 'tilepicture')
      }
    end
    commands = grid.children.detect{|c| c.name == 'commands'}
    if commands
      board['ext_sgrid_commands'] = []
      commands.css('command').each do |command|
        
        id = html_at(command, 'id')
        board[EXT_PREFIX + 'commands'] << id if id
      end
    end
    
    board['name'] = board[EXT_PREFIX + 'titlebartext'] || "board"
    board['grid'] = {
      'rows' => rows,
      'columns' => columns,
      'order' => []
    }
    rows.times do |i|
      row = []
      columns.times do |j|
        row << nil
      end
      board['grid']['order'] << row
    end
    
    buttons = []
    images = []
    button_id = 0
    image_id = 0
    grid.css('cells cell').each do |cell|
      button = {
        'id' => button_id
      }
      button_id += 1
      row = cell['x'].to_i - 1
      col = cell['y'].to_i - 1
      ['stylepreset', 'scanblock', 'magnifyx', 'magnifyy', 'tooltip', 'directactivate'].each do |attr|
        res = html_at(cell, attr)
        button[EXT_PREFIX + attr] = res if res
      end
      preset = button[EXT_PREFIX + 'stylepreset']
      if preset == 'Blank cell (no style)'
        button['background_color'] = 'rgb(255, 255, 255)'
        button['border_color'] = 'rgb(150, 150, 150)'
      elsif preset == 'Jump cell'
        button['background_color'] = 'rgb(200, 225, 255)'
        button['border_color'] = 'rgb(95, 135, 185)'
      elsif preset == 'Action cell'
        button['background_color'] = 'rgb(255, 200, 200)'
        button['border_color'] = 'rgb(155, 75, 75)'
      elsif preset == 'Vocab cell'
        button['background_color'] = 'rgb(255, 255, 155)'
        button['border_color'] = 'rgb(150, 135, 32)'
      end
      
      button['label'] = html_at(cell, 'caption')
      button[EXT_PREFIX + 'commands'] = []
      cell.css('commands command').each do |command|
        type = html_at(command, 'id')
        params = []
        command.css('parameter').each do |param|
          idx = param['index'].to_i - 1
          val = param.inner_html
          params[idx] = val
        end
        button[EXT_PREFIX + 'commands'] << {
          'type' => type,
          'parameters' => params
        }
        if type == 'type'
          button['vocalization'] = params[0]
        elsif type == 'action.clear'
          button['action'] = ':clear'
        else
          button['action'] = ":" + EXT_PREFIX + type
        end
      end
      button.delete(EXT_PREFIX + 'commands') if button[EXT_PREFIX + 'commands'].length == 0
      hidden = html_at(cell, 'hidden')
      button['hidden'] = true if hidden == 'true'
      picture = html_at(cell, 'picture')
      if picture
        image = {
          'id' => image_id
        }
        image_id += 1
        match = picture.match(/^(\[\w+\])?(.+)$/)
        symbol_set = match && match[1][1..-2]
        filename = match && match[2]
        if symbol_set
          image['symbol'] = {
            'set' => symbol_set,
            'filename' => filename
          }
        else
          image[EXT_PREFIX + 'filename'] = filename
        end
        images << image
        button['image_id'] = image['id']
      end
      
      col = cell['x'].to_i - 1
      row = cell['y'].to_i - 1
      buttons << button
      board['grid']['order'][row][col] = button['id']
    end
    board['buttons'] = buttons
    board['images'] = images
    board['sounds'] = []
    return board
  end
end