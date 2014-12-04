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
        @errored = true
        @checks[-1]['valid'] = false
        @checks[-1]['error'] = e.message
        @blocked = true if e.blocker
      end
    end
  
    def err(message, blocker=false)
      raise ValidationError.new(blocker), message
    end
    
    def warn(message)
      @warned = true
      @checks[-1]['warnings'] ||= []
      @checks[-1]['warnings'] << message
    end
    
    def self.validate_obf(path)
      v = self.new
      v.validate_obf(path)
    end
    
    def self.validate_obz(path)
    end
  
    def validate_obf(path, opts={})
      @blocked = nil
      @errored = false
      @checks = []
      
      # TODO enforce extra attributes being defined with ext_

      json = nil
      add_check('valid_json', "Valid JSON File") do
        begin
          json = JSON.parse(File.read(path))
        rescue => e
          err "Couldn't parse as JSON", true
        end
      end
    
      ext = nil
      add_check('to_external', "Valid OBF Structure") do
        begin
          ext = External.from_obf(path, {})
        rescue External::StructureError => e
          err "Couldn't parse structure: #{e.message}", true
        end
      end
    
      add_check('format_version', "Valid Format Version") do
        if !ext['format']
          err "format attribute is required, set to #{FORMAT}"
        end
        version = ext['format'].split(/-/, 3)[-1].to_f
        if version > OBF::FORMAT_CURRENT_VERSION
          err "format version (#{version}) is invalid, current version is #{OBF::FORMAT_CURRENT_VERSION}"
        elsif version < OBF::FORMAT_CURRENT_VERSION
          warn "format version (#{version}) is old, consider updating to #{OBF::FORMAT_CURRENT_VERSION}"
        end
      end
    
      add_check('id', "Valid Board ID") do
        if !ext['id']
          err "id attribute is required"
        end
      end
    
      add_check('locale', "Valid Locale") do
        if !ext['locale']
          err "locale attribute is required, please set to \"en\" for English"
        end
      end
      
      add_check('extras', "Extra Attributes") do
        attrs = ['format', 'id', 'locale', 'url', 'data_url', 'name', 'description_html', 'buttons', 'images', 'sounds', 'grid', 'license']
        ext.keys.each do |key|
          if !attrs.include?(key) && !key.match(/^ext_/)
            warn "#{key} attribute is not defined in the spec, should be prefixed with ext_yourapp_"
          end
        end
      end
    
      add_check('description', "Description Attributes") do
        if !ext['name']
          warn "name attribute is strongly recommended"
        end
        if !ext['description_html']
          warn "description_html attribute is recommended"
        end
      end
    
      add_check('buttons', "Valid buttons attribute") do
        if !ext['buttons']
          err "buttons attribute is required"
        elsif !ext['buttons'].is_a?(Array)
          err "buttons attribute must be an array"
        end
      end
    
      add_check('grid', "Valid grid attribute") do
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
      
      add_check('grid_ids', "Valid Button IDs in grid.order attribute") do
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
        warn("not all defined buttons were included in the grid order") if (button_ids = used_button_ids).length > 0
      end
      
      unless opts['obz']
        button_image_ids = []
        if ext['buttons'] && ext['buttons'].is_a?(Array)
          ext['buttons'].each{|b| button_image_ids << b['image_id'] if b.is_a?(Hash) && b['image_id'] }
        end
        add_check('images', "Valid images attribute") do
          
          if !ext['images']
            err "images attribute is required"
          elsif !ext['images'].is_a?(Array)
            err "images attribute must be an array"
          end
        end
        
        if ext['images'] && ext['images'].is_a?(Array)
          ext['images'].each_with_index do |image, idx|
            add_check("image[#{idx}]", "Valid image at [#{idx}]") do
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
              elsif !image['url'] && !image['data'] && !image['symbol']
                err "image must have data, url or symbol attribute defined"
              elsif image['data'] && !image['data'].match(/^data:image\/.+;base64,.+$/)
                err "image.data must be a valid data URI if defined"
              elsif image['symbol'] && !image['symbol'].is_a?(Hash)
                err "image.symbol must be a hash if defined"
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

        add_check('sounds', "Valid sounds attribute") do
          
          if !ext['sounds']
            err "sounds attribute is required"
          elsif !ext['sounds'].is_a?(Array)
            err "sounds attribute must be an array"
          end
        end
        
        if ext['sounds'] && ext['sounds'].is_a?(Array)
          ext['sounds'].each_with_index do |sound, idx|
            add_check("sounds[#{idx}]", "Valid sound at [#{idx}]") do
              if !sound.is_a?(Hash)
                err "sound must be a hash"
              elsif !sound['id']
                err "sound.id is required"
              elsif !sound['duration'] || !sound['duration'].is_a?(Fixnum)
                err "sound.duration must be a valid positive number"
              elsif !sound['content_type'] || !sound['content_type'].match(/^audio\/.+$/)
                err "sound.content_type must be a valid audio mime type"
              elsif !sound['url'] && !sound['data'] && !sound['symbol']
                err "sound must have data, url or symbol attribute defined"
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
      end
      
      if ext['buttons'] && ext['buttons'].is_a?(Array)
        ext['buttons'].each_with_index do |button, idx|
          add_check("buttons[#{idx}]", "Valid button at [#{idx}]") do
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

            attrs = ['id', 'label', 'vocalization', 'image_id', 'hidden', 'background_color', 'border_color', 'action', 'load_board', 'top', 'left', 'width', 'height']
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