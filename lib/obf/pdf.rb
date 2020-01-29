module OBF::PDF
  @@footer_text ||= nil
  @@footer_url ||= nil
  
  RTL_SCRIPTS = %w(Arabic Hebrew Nko Kharoshthi Phoenician Syriac Thaana Tifinagh Tamil)
  NEPALI_ALPHABET = "कखगघङचछजझञटठडढणतथदधनपफबभमयरलवशषसहक्षत्रज्ञअआइईउऊऋएऐओऔअंअः"

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
      doc_opts = {
        :page_layout => :landscape, 
        :page_size => [8.5*72, 11*72],
        :info => {
          :Title => obj['name']
        }
      }
      pdf = Prawn::Document.new(doc_opts)
      # remember: https://www.alphabet-type.com/tools/charset-checker/
      pdf.font_families.update('THFahKwangBold' => {
        normal: {font: 'THFahKwangBold', file: File.expand_path('../../THFahKwangBold.ttf', __FILE__)}
      })
      pdf.font_families.update('MiedingerBook' => {
        normal: {font: 'MiedingerBook', file: File.expand_path('../../MiedingerBook.ttf', __FILE__)}
      })
      pdf.font_families.update('Arial' => {
        normal: {font: 'Arial', file: File.expand_path('../../Arial.ttf', __FILE__)}
      })
      pdf.font_families.update('TimesNewRoman' => {
        normal: {font: 'TimesNewRoman', file: File.expand_path('../../TimesNewRoman.ttf', __FILE__)}
      })
      default_font = 'TimesNewRoman'
      if opts['font'] && !opts['font'].match(/TimesNewRoman/) && File.exists?(opts['font'])
        pdf.font_families.update('DocDefault' => {
          normal: {font: 'DocDefault', file: font}
        })
        default_font = 'DocDefault'
      else
      end
      pdf.fallback_fonts = ['TimesNewRoman', 'THFahKwangBold', 'MiedingerBook', 'Helvetica']
      pdf.font(default_font)
    
      multi_render_paths = []
      if obj['boards']
        multi_render = obj['boards'].length > 20
        obj['backlinks'] = {}
        if obj['pages']
          obj['boards'].each do |board|
            board['buttons'].each do |button|
              if button['load_board'] && button['load_board']['id']
                obj['backlinks'][button['load_board']['id']] ||= []
                obj['backlinks'][button['load_board']['id']] << obj['pages'][board['id']] if obj['pages'][board['id']]
              end
            end
          end
          OBF::Utils.log "backlinks #{obj['backlinks'].to_json}"
        end
        obj['boards'].each_with_index do |board, idx|
          started = Time.now.to_i
          OBF::Utils.log "starting pdf of board #{idx} #{board['name'] || board['id']} at #{started}"
          pre = idx.to_f / obj['boards'].length.to_f
          post = (idx + 1).to_f / obj['boards'].length.to_f
          OBF::Utils.as_progress_percent(pre, post) do
            # if more than 20 pages, build each page individually 
            # and combine them afterwards

            if multi_render
              path = OBF::Utils.temp_path("stash-#{idx}.pdf")
              pdf = Prawn::Document.new(doc_opts)
            else
              pdf.start_new_page unless idx == 0
            end
            build_page(pdf, board, {
              'zipper' => zipper, 
              'pages' => obj['pages'],
              'backlinks' => obj['backlinks'][board['id']] || [], 
              'headerless' => !!opts['headerless'], 
              'font' => default_font,
              'links' => false,
              'text_on_top' => !!opts['text_on_top'], 
              'transparent_background' => !!opts['transparent_background'],
              'symbol_background' => opts['symbol_background'],
              'text_case' => opts['text_case']
            })
            if multi_render
              pdf.render_file(path)
              multi_render_paths << path
            end
          end
          OBF::Utils.log "  finished pdf of board #{idx}/#{obj['boards'].length} #{Time.now.to_i - started}s"
        end
      else
        build_page(pdf, obj, {
          'headerless' => !!opts['headerless'], 
          'font' => font,
          'text_on_top' => !!opts['text_on_top'], 
          'transparent_background' => !!opts['transparent_background'],
          'symbol_background' => opts['symbol_background'],
          'text_case' => opts['text_case']
        })
      end
      if multi_render_paths.length > 0
        # `cp #{multi_render_paths[0]} #{dest_path}`
        `gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=#{dest_path} #{multi_render_paths.join(' ')}`
      else
        pdf.render_file(dest_path)
      end
    
    end
  end
  
  def self.rtl_regex
    @res ||= /[#{RTL_SCRIPTS.map{ |script| "\\p{#{script}}" }.join}]/
  end
  
  # b.generate_download('1_2', 'pdf', {'include' => 'all', 'headerless' => true, 'symbol_background' => 'transparent'})
  def self.build_page(pdf, obj, options)
    OBF::Utils.as_progress_percent(0, 1.0) do
      doc_width = 11*72 - 72
      doc_height = 8.5*72 - 72
      default_radius = 3
      text_height = 20
      header_height = 0
      page_num = 0
    
      if options['pages']
        page_num = options['pages'][obj['id']].to_i
        pdf.add_dest("page#{page_num}", pdf.dest_fit) if options['links']
      end
      # header
      if !options['headerless']
        header_height = 80
        pdf.bounding_box([0, doc_height], :width => doc_width, :height => header_height) do
          pdf.font('Arial')
          pdf.line_width = 2
          pdf.font_size 16
          pdf.fill_color "eeeeee"
          pdf.stroke_color "888888"
      
          include_back = options['pages'] && page_num != 1 && page_num != 0
          # Go Back
          if include_back
            OBF::Utils.log "  board backlinks #{obj['id']} #{options['backlinks'].to_json}"
            options['backlinks'] ||= []
            if options['backlinks'].length > 0
              x = 110
              pdf.fill_and_stroke_rounded_rectangle [x, header_height], 100, header_height, default_radius
              pdf.fill_color "6D81D1"
              pdf.fill_and_stroke_polygon([x + 5, 45], [x + 35, 70], [x + 35, 60], [x + 95, 60], [x + 95, 30], [x + 35, 30], [x + 35, 20])
              pdf.fill_color "666666"
              text_options = {:text => "Go Back"}
              text_options[:anchor] = "page1" if options['links']
              pdf.formatted_text_box [text_options], :at => [x + 10, header_height], :width => 80, :height => 80, :align => :center, :valign => :bottom, :overflow => :shrink_to_fit
              backlinks = (options['backlinks'] || []).join(',')
              pdf.fill_color "ffffff"
              pdf.formatted_text_box [{:text => backlinks}], :at => [x + 20, header_height + 5 - 25], :width => 70, :height => 30, :align => :center, :valign => :center, :overflow => :shrink_to_fit
            end
          end

          # Say it Out Loud
          pdf.fill_color "ffffff"
          shift = include_back ? 0 : 55
          offset = include_back ? 110 : 55
          box_shift = include_back ? 110 : 0
          
          pdf.fill_and_stroke_rounded_rectangle [110 + box_shift, header_height], 170 + shift + shift, header_height, default_radius
          pdf.fill_color "DDDB54"
          pdf.fill_and_stroke do
            pdf.move_to 160 + offset, 40
            pdf.line_to 190 + offset, 55
            pdf.curve_to [125 + offset, 40], :bounds => [[180 + offset, 80], [125 + offset, 80]]
            pdf.curve_to [190 + offset, 25], :bounds => [[125 + offset, 0], [180 + offset, 0]]
            pdf.line_to 160 + offset, 40
          end
          pdf.fill_color "444444"
          pdf.text_box "Say that out loud for me", :at => [210 + offset, header_height], :width => 60, :height => 80, :align => :center, :valign => :center, :overflow => :shrink_to_fit

          # Start Over
          x = doc_width
          pdf.fill_color "eeeeee"
          pdf.fill_and_stroke_rounded_rectangle [(doc_width - x), header_height], 100, header_height, default_radius
          pdf.fill_color "5c9c6d"
          pdf.stroke_color "25783b"
          pdf.fill_and_stroke_polygon([doc_width - x + 50, 75], [doc_width - x + 80, 50], [doc_width - x + 80, 20], [doc_width - x + 20, 20], [doc_width - x + 20, 50])
          pdf.stroke_color "888888"
          pdf.fill_color "666666"
          pdf.text_box "Start Over", :styles => [:bold], :at => [(doc_width - x + 10), header_height], :width => 80, :height => 80, :align => :center, :valign => :bottom, :overflow => :shrink_to_fit

          # Oops
          x = 210
          pdf.fill_color "eeeeee"
          pdf.fill_and_stroke_rounded_rectangle [(doc_width - x), header_height], 100, header_height, default_radius
          pdf.fill_color "6653a6"
          pdf.stroke_color "554a78"
          pdf.fill_and_stroke_polygon([doc_width - x + 50 - 7, 75], [doc_width - x + 50 + 7, 75], [doc_width - x + 50 + 7, 40], [doc_width - x + 50 - 7, 40])
          pdf.fill_and_stroke_polygon([doc_width - x + 50 - 7, 33], [doc_width - x + 50 + 7, 33], [doc_width - x + 50 + 7, 20], [doc_width - x + 50 - 7, 20])
          pdf.stroke_color "888888"
          pdf.fill_color "666666"
          pdf.text_box "Oops", :at => [(doc_width - x + 10), header_height], :width => 80, :height => 80, :align => :center, :valign => :bottom, :overflow => :shrink_to_fit

          # Stop
          x = 320
          pdf.fill_color "eeeeee"
          pdf.fill_and_stroke_rounded_rectangle [(doc_width - x), header_height], 100, header_height, default_radius
          pdf.fill_color "944747"
          pdf.stroke_color "693636"
          pdf.fill_and_stroke_polygon([doc_width - x + 39, 70], [doc_width - x + 61, 70], [doc_width - x + 75, 56], [doc_width - x + 75, 34], [doc_width - x + 61, 20], [doc_width - x + 39, 20], [doc_width - x + 25, 34], [doc_width - x + 25, 56])
          pdf.stroke_color "888888"
          pdf.fill_color "666666"
          pdf.text_box "Stop", :at => [(doc_width - x + 10), header_height], :width => 80, :height => 80, :align => :center, :valign => :bottom, :overflow => :shrink_to_fit
          
          # Clear
          x = 100
          pdf.fill_color "eeeeee"
          pdf.fill_and_stroke_rounded_rectangle [(doc_width - x), header_height], 100, header_height, default_radius
          pdf.stroke_color "666666"
          pdf.fill_color "888888"
          pdf.fill_and_stroke_polygon([doc_width - x + 10, 45], [doc_width - x + 35, 70], [doc_width - x + 90, 70], [doc_width - x + 90, 20], [doc_width - x + 35, 20])
          pdf.stroke_color "888888"
          pdf.fill_color "666666"
          pdf.text_box "Clear", :at => [(doc_width - x + 10), header_height], :width => 80, :height => 80, :align => :center, :valign => :bottom, :overflow => :shrink_to_fit
        end
      end
    
      # board
      pdf.font(options['font'])
      pdf.font_size 12
      padding = 10
      grid_height = doc_height - header_height - text_height - (padding * 2)
      grid_width = doc_width
      if obj['grid'] && obj['grid']['rows'] > 0 && obj['grid']['columns'] > 0
        button_height = (grid_height - (padding * (obj['grid']['rows'] - 1))) / obj['grid']['rows'].to_f
        button_width = (grid_width - (padding * (obj['grid']['columns'] - 1))) / obj['grid']['columns'].to_f

        # Grab all the images per board in parallel
        OBF::Utils.log "  batch-retrieving remote images"
        hydra = OBF::Utils.hydra
        grabs = []
        obj['buttons'].each do |btn|
          image = (obj['images_hash'] || {})[btn['image_id']]
          if image && image['url'] && !image['data'] && !(image['path'] && options['zipper'])
            # download the raw data from the remote URL
            url = image['url']
            res = OBF::Utils.get_url(url, true)
            if res['request']
              hydra.queue(res['request'])
              grabs << {url: url, res: res, req: res['request'], image: image, fill: btn['background_color'] ? OBF::Utils.fix_color(btn['background_color'], 'hex') : "ffffff"}
            end
          elsif image && (image['data'] || (image['path'] && options['zipper']))
            # process the data-uri or zipped image
            grabs << {image: image, fill: btn['background_color'] ? OBF::Utils.fix_color(btn['background_color'], 'hex') : "ffffff"}
          end
        end
        hydra.run
        blocks = []
        block = nil
        grabs.each do |grab|
          # prevent too many svg converts from happening at the same time
          block = block || {grabs: []}
          block[:grabs] << grab
          grab[:svg] = true if grab[:image] && grab[:image]['content_type'] && grab[:image]['content_type'].match(/svg/)
          grab[:svg] = true if grab[:res] && grab[:res]['content_type'] && grab[:res]['content_type'].match(/svg/)
          if block[:grabs].length > 20 || block[:grabs].select{|g| g[:svg] }.length > 3
            blocks << block
            block = nil
          end
        end
        blocks << block if block
        # OBF::Utils.log("  final block #{block.to_json}")
        blocks.each_with_index do |block, idx|
          threads = []
          OBF::Utils.log("   block #{idx}")
          block[:grabs].each do |grab|
            if grab[:res] && grab[:res]['data']
              grab[:image]['raw_data'] = grab[:res]['data']
              grab[:image]['content_type'] ||= grab[:res]['content_type']
              grab[:image]['extension'] ||= grab[:res]['extension']
            end
            grab[:image]['threadable'] = true
            bg = 'white'
            if options['transparent_background'] || options['symbol_background'] == 'transparent'
              bg = "\##{grab[:fill]}"
            elsif options['symbol_background'] == 'black'
              bg = 'black'
            end
            OBF::Utils.log("    img")
            res = OBF::Utils.save_image(grab[:image], options['zipper'], bg)
            threads << res if res && !res.is_a?(String)
          end
          threads.each{|t| t[:thread].join }
        end
        grabs.each do |grab|
          if grab[:image]
            grab[:image].delete('threadable')
            grab[:image].delete('local_path') unless grab[:image]['local_path'] && File.exist?(grab[:image]['local_path'])
          end
        end
        OBF::Utils.log "  done with #{grabs.length} remote images!"

        obj['grid']['order'].each_with_index do |buttons, row|
          buttons.each_with_index do |button_id, col|
            button = obj['buttons'].detect{|b| b['id'] == button_id }
            blank_button = (!button || button['hidden'] == true)
            next if options['skip_blank'] && blank_button
            x = (padding * col) + (col * button_width)
            y = text_height + padding - (padding * row) + grid_height - (row * button_height)
            pdf.bounding_box([x, y], :width => button_width, :height => button_height) do
              fill = "ffffff"
              border = "eeeeee"
              if !blank_button && button['background_color']
                fill = OBF::Utils.fix_color(button['background_color'], 'hex')
              end   
              if !blank_button && button['border_color']
                border = OBF::Utils.fix_color(button['border_color'], 'hex')
              end         
              pdf.fill_color fill
              pdf.stroke_color border
              pdf.fill_and_stroke_rounded_rectangle [0, button_height], button_width, button_height, default_radius
              if !blank_button
                vertical = options['text_on_top'] ? button_height - text_height : button_height - 5

                text = (button['label'] || button['vocalization']).to_s
                font = options['font']
                # Nepali text isn't working as a fallback for some reason, it says "bad font family"
                if text.match(Regexp.new("[" + NEPALI_ALPHABET + "]"))
                  font = File.expand_path('../../MiedingerBook.ttf', __FILE__)
                end
                pdf.font(font)
                direction = text.match(rtl_regex) ? :rtl : :ltr
                if options['text_case'] == 'upper'
                  text = text.upcase
                elsif options['text_case'] == 'lower'
                  text = text.downcase
                end
                text_color = OBF::Utils.fix_color(fill, 'contrast')
                
                if options['text_only']
                  # render text
                  pdf.fill_color text_color
                  pdf.text_box text, :at => [0, 0], :width => button_width, :height => button_height, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction
                else
                  # render image
                  pdf.bounding_box([5, vertical], :width => button_width - 10, :height => button_height - text_height - 5) do
                    image = (obj['images_hash'] || {})[button['image_id']]
                    if image
                      bg = 'white'
                      if options['transparent_background'] || options['symbol_background'] == 'transparent'
                        bg = "\##{fill}"
                      elsif options['symbol_background'] == 'black'
                        bg = 'black'
                      end
                      image['threadable'] = false
                      image_local_path = image['local_path'] if image && image['local_path'] && File.exist?(image['local_path'])
                      image_local_path ||= image && OBF::Utils.save_image(image, options['zipper'], bg)
                      if image_local_path && File.exist?(image_local_path)
                        pdf.image(image_local_path, :fit => [button_width - 10, button_height - text_height - 5], :position => :center, :vposition => :center) rescue nil
                        File.unlink image_local_path
                      else
                        OBF::Utils.log("  missing image #{image['id']} #{image_local_path}")
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
                      pdf.fill_color text_color
                      text_options = {:text => page}
                      text_options[:anchor] = "page#{page}" if options['links']
                      pdf.formatted_text_box [text_options], :at => [button_width - 18, page_vertical], :width => 20, :height => text_height, :align => :center, :valign => :center
                    end
                  end
                
                  # render text
                  pdf.fill_color text_color
                  vertical = options['text_on_top'] ? button_height : text_height
                  pdf.text_box text, :at => [0, vertical], :width => button_width, :height => text_height, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction
                end
              end
            end
            index = col + (row * obj['grid']['columns'])
            OBF::Utils.update_current_progress(index.to_f / (obj['grid']['rows'] * obj['grid']['columns']).to_f)
          end
        end
      end
    
      # footer
      pdf.fill_color "bbbbbb"
      obj['name'] = nil if obj['name'] == 'Unnamed Board'
      pdf.font('Arial')
      if OBF::PDF.footer_text || obj['name']
        text = [obj['name'], OBF::PDF.footer_text].compact.join(', ')
        offset = options['pages'] ? 400 : 300
        pdf.formatted_text_box [{:text => text, :link => OBF::PDF.footer_url}], :at => [doc_width - offset, text_height], :width => 300, :height => text_height, :align => :right, :valign => :center, :overflow => :shrink_to_fit
      end
      pdf.fill_color "000000"
      if options['pages'] && page_num != 0
        text_options = {:text => page_num.to_s}
        text_options[:anchor] = "page1" if options['links']
        pdf.formatted_text_box [text_options], :at => [doc_width - 100, text_height], :width => 100, :height => text_height, :align => :right, :valign => :center, :overflow => :shrink_to_fit
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
  
  def self.from_external(content, dest_path, opts={})
    tmp_path = OBF::Utils.temp_path("stash")
    if content['boards']
      from_obz(OBF::OBZ.from_external(content, tmp_path, opts), dest_path, opts)
    else
      from_obf(OBF::OBF.from_external(content, tmp_path), dest_path, nil, opts)
    end
    File.unlink(tmp_path) if File.exist?(tmp_path)
    dest_path
  end
  
  def self.to_png(pdf, dest_path)
    OBF::PNG.from_pdf(pdf, dest_path)
  end
end


# pdf = Prawn::Document.new
# pdf.font "lib/TimesNewRoman.ttf"
# pdf.font_families.update({'MiedingerBook' => {
#   normal: "lib/MiedingerBook.ttf" # https://fontlibrary.org/en/font/miedinger
# }})
# pdf.fallback_fonts = ['MiedingerBook']
# pdf.text_box "भन्नुहोस्"
# pdf.render_file("out/prawn.pdf")
