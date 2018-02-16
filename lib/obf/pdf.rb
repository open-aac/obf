module OBF::PDF
  @@footer_text ||= nil
  @@footer_url ||= nil
  
  RTL_SCRIPTS = %w(Arabic Hebrew Nko Kharoshthi Phoenician Syriac Thaana Tifinagh)
  
  def self.footer_text
    @@footer_text
  end
  
  def self.footer_text=(text)
    @@footer_text = text
  end

  def self.footer_url
    @@footer_url
  end
  
  def self.footer_url=(url)
    @@footer_url = url
  end
  
  def self.from_obf(obf_json_or_path, dest_path, zipper=nil, opts={})
    obj = obf_json_or_path
    if obj.is_a?(String)
      obj = OBF::Utils.parse_obf(File.read(obf_json_or_path))
    else
      obj = OBF::Utils.parse_obf(obf_json_or_path)
    end
    build_pdf(obj, dest_path, zipper, opts)
    return dest_path
  end
  
  def self.build_pdf(obj, dest_path, zipper, opts={})
    OBF::Utils.as_progress_percent(0, 1.0) do
      # parse obf, draw as pdf
      pdf = Prawn::Document.new(
        :page_layout => :landscape, 
        :page_size => [8.5*72, 11*72],
        :info => {
          :Title => obj['name']
        }
      )
      font = opts['font'] if opts['font'] && File.exists?(opts['font'])
      font ||= File.expand_path('../../TimesNewRoman.ttf', __FILE__)
      pdf.font(font) if File.exists?(font)
    
    
      if obj['boards']
        obj['boards'].each_with_index do |board, idx|
          pre = idx.to_f / obj['boards'].length.to_f
          post = (idx + 1).to_f / obj['boards'].length.to_f
          OBF::Utils.as_progress_percent(pre, post) do
            pdf.start_new_page unless idx == 0
            build_page(pdf, board, {
              'zipper' => zipper, 
              'pages' => obj['pages'], 
              'headerless' => !!opts['headerless'], 
              'font' => font,
              'text_on_top' => !!opts['text_on_top'], 
              'transparent_background' => !!opts['transparent_background'],
              'text_case' => opts['text_case']
            })
          end
        end
      else
        build_page(pdf, obj, {
          'headerless' => !!opts['headerless'], 
          'font' => font,
          'text_on_top' => !!opts['text_on_top'], 
          'transparent_background' => !!opts['transparent_background'],
          'text_case' => opts['text_case']
        })
      end
    
      pdf.render_file(dest_path)
    end
  end
  
  def self.rtl_regex
    @res ||= /[#{RTL_SCRIPTS.map{ |script| "\\p{#{script}}" }.join}]/
  end
  
  def self.build_page(pdf, obj, options)
    OBF::Utils.as_progress_percent(0, 1.0) do
      pdf.font(options['font']) if options['font'] && File.exists?(options['font'])
      doc_width = 11*72 - 72
      doc_height = 8.5*72 - 72
      default_radius = 3
      text_height = 20
      header_height = 0
    
      if options['pages']
        page_num = options['pages'][obj['id']]
        pdf.add_dest("page#{page_num}", pdf.dest_fit)
      end
      # header
      if !options['headerless']
        header_height = 100
        pdf.bounding_box([0, doc_height], :width => doc_width, :height => 100) do
          pdf.line_width = 2
          pdf.font_size 16
        
          pdf.fill_color "eeeeee"
          pdf.stroke_color "888888"
          pdf.fill_and_stroke_rounded_rectangle [0, 100], 100, 100, default_radius
          pdf.fill_color "6D81D1"
          pdf.fill_and_stroke_polygon([5, 50], [35, 85], [35, 70], [95, 70], [95, 30], [35, 30], [35, 15])
          pdf.fill_color "ffffff"
          pdf.formatted_text_box [{:text => "Go Back", :anchor => "page1"}], :at => [10, 90], :width => 80, :height => 80, :align => :center, :valign => :center, :overflow => :shrink_to_fit
          pdf.fill_color "ffffff"
          pdf.fill_and_stroke_rounded_rectangle [110, 100], (doc_width - 200 - 20), 100, default_radius
          pdf.fill_color "DDDB54"
          pdf.fill_and_stroke do
            pdf.move_to 160, 50
            pdf.line_to 190, 70
            pdf.curve_to [190, 30], :bounds => [[100, 130], [100, -30]]
            pdf.line_to 160, 50
          end
          pdf.fill_color "444444"
          pdf.text_box "Say that sentence out loud for me", :at => [210, 90], :width => (doc_width - 200 - 120), :height => 80, :align => :left, :valign => :center, :overflow => :shrink_to_fit
          pdf.fill_color "eeeeee"
          pdf.fill_and_stroke_rounded_rectangle [(doc_width - 100), 100], 100, 100, default_radius
          pdf.fill_color "aaaaaa"
          pdf.fill_and_stroke_polygon([doc_width - 100 + 5, 50], [doc_width - 100 + 35, 85], [doc_width - 100 + 95, 85], [doc_width - 100 + 95, 15], [doc_width - 100 + 35, 15])
          pdf.fill_color "ffffff"
          pdf.text_box "Erase", :at => [(doc_width - 100 + 10), 90], :width => 80, :height => 80, :align => :center, :valign => :center, :overflow => :shrink_to_fit
        end
      end
    
      # board
      pdf.font_size 12
      padding = 10
      grid_height = doc_height - header_height - text_height - (padding * 2)
      grid_width = doc_width
      if obj['grid'] && obj['grid']['rows'] > 0 && obj['grid']['columns'] > 0
        button_height = (grid_height - (padding * (obj['grid']['rows'] - 1))) / obj['grid']['rows'].to_f
        button_width = (grid_width - (padding * (obj['grid']['columns'] - 1))) / obj['grid']['columns'].to_f
        obj['grid']['order'].each_with_index do |buttons, row|
          buttons.each_with_index do |button_id, col|
            button = obj['buttons'].detect{|b| b['id'] == button_id }
            next if !button || button['hidden'] == true
            x = (padding * col) + (col * button_width)
            y = text_height + padding - (padding * row) + grid_height - (row * button_height)
            pdf.bounding_box([x, y], :width => button_width, :height => button_height) do
              fill = "ffffff"
              border = "eeeeee"
              if button['background_color']
                fill = OBF::Utils.fix_color(button['background_color'], 'hex')
              end   
              if button['border_color']
                border = OBF::Utils.fix_color(button['border_color'], 'hex')
              end         
              pdf.fill_color fill
              pdf.stroke_color border
              pdf.fill_and_stroke_rounded_rectangle [0, button_height], button_width, button_height, default_radius
              vertical = options['text_on_top'] ? button_height - text_height : button_height - 5

              font = options['font']
              if text.match(/\p{Thai}/)
                font = File.expand_path('../../THFahKwangBold.ttf', __FILE__)
              end
              pdf.font(font) if font && File.exists?(font)
              text = (button['label'] || button['vocalization']).to_s
              direction = text.match(rtl_regex) ? :rtl : :ltr
              if options['text_case'] == 'upper'
                text = text.upcase
              elsif options['text_case'] == 'lower'
                text = text.downcase
              end
              
              if options['text_only']
                # render text
                pdf.fill_color "000000"
                pdf.text_box text, :at => [0, 0], :width => button_width, :height => button_height, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction
              else
                # render image
                pdf.bounding_box([5, vertical], :width => button_width - 10, :height => button_height - text_height - 5) do
                  image = (obj['images_hash'] || {})[button['image_id']]
                  if image
                    bg = 'white'
                    if options['transparent_background']
                      bg = "\##{fill}"
                    end
                    image_local_path = image && OBF::Utils.save_image(image, options['zipper'], bg)
                    if image_local_path && File.exist?(image_local_path)
                      pdf.image image_local_path, :fit => [button_width - 10, button_height - text_height - 5], :position => :center, :vposition => :center
                      File.unlink image_local_path
                    end
                  end
                end
                if options['pages'] && button['load_board']
                  page = options['pages'][button['load_board']['id']]
                  if page
                    page_vertical = options['text_on_top'] ? -2 + text_height : button_height + 2
                    pdf.fill_color "ffffff"            
                    pdf.stroke_color "eeeeee"            
                    pdf.fill_and_stroke_rounded_rectangle [button_width - 18, page_vertical], 20, text_height, 5
                    pdf.fill_color "000000"
                    pdf.formatted_text_box [{:text => page, :anchor => "page#{page}"}], :at => [button_width - 18, page_vertical], :width => 20, :height => text_height, :align => :center, :valign => :center
                  end
                end
              
                # render text
                pdf.fill_color "000000"
                vertical = options['text_on_top'] ? button_height : text_height
                pdf.text_box text, :at => [0, vertical], :width => button_width, :height => text_height, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction
              end
              pdf.font(options['font']) if options['font'] && File.exists?(options['font'])
            end
            index = col + (row * obj['grid']['columns'])
            OBF::Utils.update_current_progress(index.to_f / (obj['grid']['rows'] * obj['grid']['columns']).to_f)
          end
        end
      end
    
      # footer
      pdf.fill_color "aaaaaa"
      if OBF::PDF.footer_text
        text = OBF::PDF.footer_text
        pdf.formatted_text_box [{:text => text, :link => OBF::PDF.footer_url}], :at => [doc_width - 300, text_height], :width => 200, :height => text_height, :align => :right, :valign => :center, :overflow => :shrink_to_fit
      end
      pdf.fill_color "000000"
      if options['pages']
        pdf.formatted_text_box [{:text => options['pages'][obj['id']], :anchor => "page1"}], :at => [doc_width - 100, text_height], :width => 100, :height => text_height, :align => :right, :valign => :center, :overflow => :shrink_to_fit
      end
    end
  end
  
  def self.from_obz(obz_path, dest_path, opts={})
    OBF::Utils.load_zip(obz_path) do |zipper|
      manifest = JSON.parse(zipper.read('manifest.json'))
      root = manifest['root']
      board = OBF::Utils.parse_obf(zipper.read(root))
      board['path'] = root
      unvisited_boards = [board]
      visited_boards = []
      while unvisited_boards.length > 0
        board = unvisited_boards.shift
        visited_boards << board
        children = []
        board['buttons'].each do |button|
          if button['load_board']
            children << button['load_board']
            all_boards = visited_boards + unvisited_boards
            if all_boards.none?{|b| b['id'] == button['load_board']['id'] || b['path'] == button['load_board']['path'] }
              path = button['load_board']['path'] || (manifest['paths'] && manifest['paths']['boards'] && manifest['paths']['boards'][button['load_board']['id']])
              if path
                b = OBF::Utils.parse_obf(zipper.read(path))
                b['path'] = path
                button['load_board']['id'] = b['id']
                unvisited_boards << b
              end
            end
          end
        end
      end
      
      pages = {}
      visited_boards.each_with_index do |board, idx|
        pages[board['id']] = (idx + 1).to_s
      end
      
      build_pdf({
        'name' => 'Communication Board Set',
        'boards' => visited_boards,
        'pages' => pages
      }, dest_path, zipper, opts)
    end
    # parse obz, draw as pdf

    # TODO: helper files included at the end for emergencies (eg. body parts)
    
    return dest_path
  end
  
  def self.from_external(content, dest_path)
    tmp_path = OBF::Utils.temp_path("stash")
    if content['boards']
      from_obz(OBF::OBZ.from_external(content, tmp_path), dest_path)
    else
      from_obf(OBF::OBF.from_external(content, tmp_path), dest_path)
    end
    File.unlink(tmp_path) if File.exist?(tmp_path)
    dest_path
  end
  
  def self.to_png(pdf, dest_path)
    OBF::PNG.from_pdf(pdf, dest_path)
  end
end