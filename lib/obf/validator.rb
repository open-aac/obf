module OBF
  class Validator
    def add_check(type, description, &block)
      return if @blocked
      @checks << {
        'type' => type,
        'description' => description,
        'valid' => true
      }
      begin
        block.call
      rescue ValidationError => e
        @errors += 1
        @checks[-1]['valid'] = false
        @checks[-1]['error'] = e.message
        @blocked = true if e.blocker
      end
    end
  
    def err(message, blocker=false)
      raise ValidationError.new(blocker), message
    end
    
    def warn(message)
      @warnings += 1
      @checks[-1]['warnings'] ||= []
      @checks[-1]['warnings'] << message
    end
    
    def errors
      @errors || 0
    end
    
    def warnings
      @warnings || 0
    end
    
    def self.validate_file(path)
      type = Utils::identify_file(path)
      fn = File.basename(path)
      filesize = File.size(path)
      if type == :obf
        validate_obf(path)
      elsif type == :obz
        validate_obz(path)
      else
        {
          :filename => fn,
          :filesize => filesize,
          :valid => false,
          :errors => 1,
          :results => [{
            'type' => 'valid_file',
            'description' => 'valid .obf or .obz file',
            'valid' => false,
            'error' => 'file must be an .obf JSON file or a .obz zip package'
          }]
        }
      end
    end
    
    def self.validate_obf(path, opts={})
      v = self.new
      fn = fn
      filesize = 0
      content = nil
      if opts['zipper']
        fn = path
        content = opts['zipper'].read(path)
        filesize = opts['zipper'].glob(path)[0].size
      else
        fn = File.basename(path)
        content = File.read(path)
        filesize = File.size(path)
      end
      results = v.validate_obf(content, fn, opts)
      {
        :filename => fn,
        :filesize => filesize,
        :valid => v.errors == 0,
        :errors => v.errors,
        :warnings => v.warnings,
        :results => results
      }
    end
    
    def self.validate_obz(path)
      v = self.new
      fn = File.basename(path)
      results, sub_results = v.validate_obz(path, fn)
      errors = ([v.errors] + sub_results.map{|r| r[:errors] }).inject(:+)
      warnings = ([v.warnings] + sub_results.map{|r| r[:warnings] }).inject(:+)
      {
        :filename => fn,
        :filesize => File.size(path),
        :valid => errors == 0,
        :errors => errors,
        :warnings => warnings,
        :results => results,
        :sub_results => sub_results
      }
    end
    
    def setup
      @blocked = nil
      @errored = false
      @warnings = 0
      @errors = 0
      @checks = []
      @sub_checks = []
    end
    
    def validate_obz(path, filename)
      setup
      
      add_check('filename', "file name") do
        if !filename.match(/\.obz$/)
          warn "filename should end with .obz"
        end
      end
      
      valid_zip = false
      add_check('zip', 'valid zip') do
        begin
          Utils::load_zip(path) do |zipper|
          end
          valid_zip = true
        rescue Zip::Error => e
          err "file is not a valid zip package"
        end
      end
      if valid_zip
        Utils::load_zip(path) do |zipper|
          json = nil
          add_check('manifest', 'manifest.json') do
            if zipper.glob('manifest.json').length == 0
              err "manifest.json is required in the zip package"
            end
            json = JSON.parse(zipper.read('manifest.json')) rescue nil
            if !json
              err "manifest.json must contain a valid JSON structure"
            end
          end
          if json
            add_check('manifest_format', 'manifest.json format version') do
              if !json['format']
                err "format attribute is required, set to #{OBF::FORMAT}"
              end
              version = json['format'].split(/-/, 3)[-1].to_f
              if version > OBF::FORMAT_CURRENT_VERSION
                err "format version (#{version}) is invalid, current version is #{OBF::FORMAT_CURRENT_VERSION}"
              elsif version < OBF::FORMAT_CURRENT_VERSION
                warn "format version (#{version}) is old, consider updating to #{OBF::FORMAT_CURRENT_VERSION}"
              end
            end
            
            add_check('manifest_root', 'manifest.json root attribute') do
              if !json['root']
                err "root attribute is required"
              end
              if zipper.glob(json['root']).length == 0
                err "root attribute must reference a file in the package"
              end
            end
            
            paths = nil
            add_check('manifest_paths', 'manifest.json paths attribute') do
              if !json['paths'] || !json['paths'].is_a?(Hash)
                err "paths attribute must be a valid hash"
              end
              if !json['paths']['boards'] || !json['paths']['boards'].is_a?(Hash)
                err "paths.boards must be a valid hash"
              end
              if json['paths']['images'] && !json['paths']['images'].is_a?(Hash)
                err "paths.images must be a valid hash if defined"
              end
              if json['paths']['sounds'] && !json['paths']['sounds'].is_a?(Hash)
                err "paths.sounds must be a valid hash if defined"
              end
            end
            add_check('manifest_extras', 'manifest.json extra attributes') do
              attrs = ['format', 'root', 'paths']
              json.keys.each do |key|
                if !attrs.include?(key) && !key.match(/^ext_/)
                  warn "#{key} attribute is not defined in the spec, should be prefixed with ext_yourapp_"
                end
              end

              attrs = ['boards', 'images', 'sounds']
              json['paths'].keys.each do |key|
                if !attrs.include?(key) && !key.match(/^ext_/)
                  warn "paths.#{key} attribute is not defined in the spec, should be prefixed with ext_yourapp_"
                end
              end
            end
            
            found_paths = ['manifest.json']
            if json['paths'] && json['paths']['boards'] && json['paths']['boards'].is_a?(Hash)
              json['paths']['boards'].each do |id, path|
                add_check("manifest_boards[#{id}]", "manifest.json path.boards.#{id}") do
                  found_paths << path
                  if !zipper.glob(path)
                    err "board path (#{path}) not found in the zip package"
                  end
                  board_json = JSON.parse(zipper.read(path)) rescue nil
                  if !board_json || board_json['id'] != id
                    err "board at path (#{path}) defined in manifest with id \"#{id}\" but actually has id \"#{board_json['id']}\""
                  end
                end
              end
            end

            if json['paths'] && json['paths']['images'] && json['paths']['images'].is_a?(Hash)
              json['paths']['images'].each do |id, path|
                add_check("manifest_images[#{id}]", "manifest.json path.images.#{id}") do
                  found_paths << path
                  if !zipper.glob(path)
                    err "image path (#{path}) not found in the zip package"
                  end
                end
              end
            end            

            if json['paths'] && json['paths']['sounds'] && json['paths']['sounds'].is_a?(Hash)
              json['paths']['sounds'].each do |id, path|
                add_check("manifest_sounds[#{id}]", "manifest.json path.sounds.#{id}") do
                  found_paths << path
                  if !zipper.glob(path)
                    err "sound path (#{path}) not found in the zip package"
                  end
                end
              end
            end
            
            actual_paths = zipper.all_files
            add_check('extra_paths', 'manifest.json extra paths') do
              (actual_paths - found_paths).each do |path|
                warn "the file \"#{path}\" isn't listed in manifest.json"
              end
            end
            
            sub_results = []
            if json['paths'] && json['paths']['boards'] && json['paths']['boards'].is_a?(Hash)
              json['paths']['boards'].each do |key, path|
                sub = Validator.validate_obf(path, {'zipper' => zipper})
                sub_results << sub
              end
            end
            @sub_checks = sub_results
          end
          
          if zipper.glob('manifest.json').length > 0
            json = JSON.parse(zipper.read('manifest.json')) rescue nil
            if json['root'] && json['format'] && json['format'].match(/^open-board-/)
              type = :obz
            end
          end
        end
      end
      return [@checks, @sub_checks]
    end
  
    def validate_obf(content, filename, opts={})
      setup
      
      # TODO enforce extra attributes being defined with ext_

      add_check('filename', "file name") do
        if !filename.match(/\.obf$/)
          warn "filename should end with .obf"
        end
      end
      
      json = nil
      add_check('valid_json', "JSON file") do
        begin
          json = JSON.parse(content)
        rescue => e
          err "Couldn't parse as JSON", true
        end
      end
    
      ext = nil
      add_check('to_external', "OBF structure") do
        begin
          External.from_obf(json, {})
          ext = JSON.parse(content)
        rescue External::StructureError => e
          err "Couldn't parse structure: #{e.message}", true
        end
      end
      
      add_check('format_version', "format version") do
        if !ext['format']
          err "format attribute is required, set to #{OBF::FORMAT}"
        end
        version = ext['format'].split(/-/, 3)[-1].to_f
        if version > OBF::FORMAT_CURRENT_VERSION
          err "format version (#{version}) is invalid, current version is #{OBF::FORMAT_CURRENT_VERSION}"
        elsif version < OBF::FORMAT_CURRENT_VERSION
          warn "format version (#{version}) is old, consider updating to #{OBF::FORMAT_CURRENT_VERSION}"
        end
      end
    
      add_check('id', "board ID") do
        if !ext['id']
          err "id attribute is required"
        end
      end
    
      add_check('locale', "locale") do
        if !ext['locale']
          err "locale attribute is required, please set to \"en\" for English"
        end
      end
      
      add_check('extras', "extra attributes") do
        attrs = ['format', 'id', 'locale', 'url', 'data_url', 'name', 'description_html', 'buttons', 'images', 'sounds', 'grid', 'license']
        ext.keys.each do |key|
          if !attrs.include?(key) && !key.match(/^ext_/)
            warn "#{key} attribute is not defined in the spec, should be prefixed with ext_yourapp_"
          end
        end
      end
    
      add_check('description', "descriptive attributes") do
        if !ext['name']
          warn "name attribute is strongly recommended"
        end
        if !ext['description_html']
          warn "description_html attribute is recommended"
        end
      end
    
      add_check('buttons', "buttons attribute") do
        if !ext['buttons']
          err "buttons attribute is required"
        elsif !ext['buttons'].is_a?(Array)
          err "buttons attribute must be an array"
        end
      end
    
      add_check('grid', "grid attribute") do
        if !ext['grid']
          err "grid attribute is required"
        elsif !ext['grid'].is_a?(Hash)
          err "grid attribute must be a hash"
        elsif !ext['grid']['rows'].is_a?(Fixnum) || ext['grid']['rows'] < 1
          err "grid.row attribute must be a valid positive number"
        elsif !ext['grid']['columns'].is_a?(Fixnum) || ext['grid']['columns'] < 1
          err "grid.column attribute must be a valid positive number"
        end
        if ext['grid']['rows'] > 20
          warn "grid.row (#{ext['grid']['rows']}) is probably too large a number for most systems"
        end
        if ext['grid']['columns'] > 20
          warn "grid.column (#{ext['grid']['columns']}) is probably too large a number for most systems"
        end
        if !ext['grid']['order']
          err "grid.order is required"
        elsif !ext['grid']['order'].is_a?(Array)
          err "grid.order must be an array of arrays"
        elsif ext['grid']['order'].length != ext['grid']['rows']
          err "grid.order length (#{ext['grid']['order'].length}) must match grid.rows (#{ext['grid']['rows']})"
        elsif !ext['grid']['order'].all?{|r| r.is_a?(Array) && r.length == ext['grid']['columns'] }
          err "grid.order must contain #{ext['grid']['rows']} arrays each of size #{ext['grid']['columns']}"
        end

        attrs = ['rows', 'columns', 'order']
        ext['grid'].keys.each do |key|
          if !attrs.include?(key) && !key.match(/^ext_/)
            warn "grid.#{key} attribute is not defined in the spec, should be prefixed with ext_yourapp_"
          end
        end
      end
      
      add_check('grid_ids', "button IDs in grid.order attribute") do
        button_ids = []
        if ext['buttons'] && ext['buttons'].is_a?(Array)
          ext['buttons'].each{|b| button_ids << b['id'] if b.is_a?(Hash) && b['id'] }
        end
        used_button_ids = []
        if ext['grid'] && ext['grid']['order'] && ext['grid']['order'].is_a?(Array)
          ext['grid']['order'].each do |row|
            if row.is_a?(Array)
              row.each do |id|
                if id
                  used_button_ids << id
                  if !button_ids.include?(id)
                    err "grid.order references button with id #{id} but no button with that id found in buttons attribute"
                  end
                end
              end
            end
          end
        end
        warn("board has no buttons defined in the grid") if used_button_ids.length == 0
        warn("not all defined buttons were included in the grid order (#{(button_ids - used_button_ids).join(',')})") if (button_ids - used_button_ids).length > 0
      end
      
      button_image_ids = []
      if ext && ext['buttons'] && ext['buttons'].is_a?(Array)
        ext['buttons'].each{|b| button_image_ids << b['image_id'] if b.is_a?(Hash) && b['image_id'] }
      end
      add_check('images', "images attribute") do
        
        if !ext['images']
          err "images attribute is required"
        elsif !ext['images'].is_a?(Array)
          err "images attribute must be an array"
        end
      end
      
      if ext && ext['images'] && ext['images'].is_a?(Array)
        ext['images'].each_with_index do |image, idx|
          add_check("image[#{idx}]", "image at images[#{idx}]") do
            if !image.is_a?(Hash)
              err "image must be a hash"
            elsif !image['id']
              err "image.id is required"
            elsif !image['width'] || !image['width'].is_a?(Fixnum)
              err "image.width must be a valid positive number"
            elsif !image['height'] || !image['height'].is_a?(Fixnum)
              err "image.height must be a valid positive number"
            elsif !image['content_type'] || !image['content_type'].match(/^image\/.+$/)
              err "image.content_type must be a valid image mime type"
            elsif !image['url'] && !image['data'] && !image['symbol'] && !image['path']
              err "image must have data, url, path or symbol attribute defined"
            elsif image['data'] && !image['data'].match(/^data:image\/.+;base64,.+$/)
              err "image.data must be a valid data URI if defined"
            elsif image['symbol'] && !image['symbol'].is_a?(Hash)
              err "image.symbol must be a hash if defined"
            end
            if image['path']
              if opts['zipper']
                if opts['zipper'].glob(image['path']).length == 0
                  err "image.path \"#{image['path']}\" not found in .obz package"
                end
              else
                err "image.path should not be defined outside of an .obz package"
              end
            end
            
            attrs = ['id', 'width', 'height', 'content_type', 'data', 'url', 'symbol', 'path', 'data_url', 'license']
            image.keys.each do |key|
              if !attrs.include?(key) && !key.match(/^ext_/)
                warn "image.#{key} attribute is not defined in the spec, should be prefixed with ext_yourapp_"
              end
            end
          end
        end
      end

      add_check('sounds', "sounds attribute") do
        if !ext['sounds']
          err "sounds attribute is required"
        elsif !ext['sounds'].is_a?(Array)
          err "sounds attribute must be an array"
        end
      end
      
      if ext && ext['sounds'] && ext['sounds'].is_a?(Array)
        ext['sounds'].each_with_index do |sound, idx|
          add_check("sounds[#{idx}]", "sound at sounds[#{idx}]") do
            if !sound.is_a?(Hash)
              err "sound must be a hash"
            elsif !sound['id']
              err "sound.id is required"
            elsif !sound['duration'] || !sound['duration'].is_a?(Fixnum)
              err "sound.duration must be a valid positive number"
            elsif !sound['content_type'] || !sound['content_type'].match(/^audio\/.+$/)
              err "sound.content_type must be a valid audio mime type"
            elsif !sound['url'] && !sound['data'] && !sound['symbol'] && !sound['path']
              err "sound must have data, url, path or symbol attribute defined"
            elsif sound['data'] && !sound['data'].match(/^data:audio\/.+;base64,.+$/)
              err "sound.data must be a valid data URI if defined"
            end
            
            attrs = ['id', 'duration', 'content_type', 'data', 'url', 'path', 'data_url', 'license']
            sound.keys.each do |key|
              if !attrs.include?(key) && !key.match(/^ext_/)
                warn "sound.#{key} attribute is not defined in the spec, should be prefixed with ext_yourapp_"
              end
            end
          end
        end
      end
      
      if ext && ext['buttons'] && ext['buttons'].is_a?(Array)
        ext['buttons'].each_with_index do |button, idx|
          add_check("buttons[#{idx}]", "button at buttons[#{idx}]") do
            if !button.is_a?(Hash)
              err "button must be a hash"
            elsif !button['id']
              err "button.id is required"
            elsif !button['label']
              err "button.label is required"
            end
            ['top', 'left', 'width', 'height'].each do |attr|
              if button[attr] && ((!button[attr].is_a?(Fixnum) && !button[attr].is_a?(Float)) || button[attr] < 0)
                warn "button.#{attr} should be a positive number"
              end
            end
            ['background_color', 'border_color'].each do |color|
              if button[color]
                if !button[color].match(/^\s*rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*(,\s*[01]\.?\d*)?\)\s*/)
                  err "button.#{color} must be a valid rgb or rgba value if defined (\"#{button[color]}\" is invalid)"
                end
              end
            end
            if button['hidden'] != nil && button['hidden'] != true && button['hidden'] != false
              err "button.hidden must be a boolean if defined"
            end
            if !button['image_id']
              warn "button.image_id is recommended"
            end
            if button['action'] && !button['action'].match(/^(:|\+)/)
              err "button.action must start with either : or + if defined"
            end

            attrs = ['id', 'label', 'vocalization', 'image_id', 'sound_id', 'hidden', 'background_color', 'border_color', 'action', 'load_board', 'top', 'left', 'width', 'height']
            button.keys.each do |key|
              if !attrs.include?(key) && !key.match(/^ext_/)
                warn "button.#{key} attribute is not defined in the spec, should be prefixed with ext_yourapp_"
              end
            end
            
          end
        end
      end
      
      return @checks
    end
  
    class ValidationWarning < StandardError; end
    class ValidationError < StandardError
      attr_reader :blocker
      def initialize(blocker=false)
        @blocker = blocker
      end
    end
  end
end