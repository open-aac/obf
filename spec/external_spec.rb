require 'spec_helper'

describe OBF::External do
  describe "to_obf" do
    it "should render a basic board" do
      b = external_board
      file = Tempfile.new("stash")
      OBF::External.to_obf(b, file.path)
      json = JSON.parse(file.read)
      file.unlink
      expect(json['id']).to eq(b['id'])
      expect(json['name']).to eq('Unnamed Board')
      expect(json['default_layout']).to eq('landscape')
      expect(json['url']).to eq("http://www.boards.com/example")
      expect(json['grid']).to eq({
        'rows' => 0,
        'columns' => 0,
        'order' => [[]]
      })
      expect(json['buttons']).to eq([])
    end
    
    it "should include buttons" do
      b = external_board
      b['name'] = "My Board"
      b['buttons'] = [
        {'id' => 1, 'label' => 'chicken'},
        {'id' => 2, 'label' => 'nuggets'},
        {'id' => 3, 'label' => 'sauce', 'vocalization' => 'I like sauce'}
      ]
      b['grid'] = {
        'rows' => 2,
        'columns' => 2,
        'order' => [[1,2],[3,2]]
      }
      file = Tempfile.new("stash")
      OBF::External.to_obf(b, file.path)
      json = JSON.parse(file.read)
      file.unlink
      expect(json['id']).to eq(b['id'])
      expect(json['name']).to eq('My Board')
      expect(json['default_layout']).to eq('landscape')
      expect(json['url']).to eq("http://www.boards.com/example")
      expect(json['grid']).to eq({
        'rows' => 2,
        'columns' => 2,
        'order' => [[1, 2], [3, 2]]
      })
      expect(json['buttons'].length).to eq(3)
      expect(json['buttons'][0]).to eq({
        'id' => 1,
        'label' => 'chicken', 
        'vocalization' => nil,
        'left' => nil,
        'top' => nil,
        'width' => nil,
        'height' => nil,
        'border_color' => '#aaa',
        'background_color' => '#fff'
      })
      expect(json['buttons'][1]).to eq({
        'id' => 2,
        'label' => 'nuggets', 
        'vocalization' => nil,
        'left' => nil,
        'top' => nil,
        'width' => nil,
        'height' => nil,
        'border_color' => '#aaa',
        'background_color' => '#fff'
      })
      expect(json['buttons'][2]).to eq({
        'id' => 3,
        'label' => 'sauce', 
        'vocalization' => "I like sauce",
        'left' => nil,
        'top' => nil,
        'width' => nil,
        'height' => nil,
        'border_color' => '#aaa',
        'background_color' => '#fff'
      })
    end
    
    it "should link to external boards" do
      ref = external_board
      b = external_board
      b['name'] = "My Board"
      b['buttons'] = [
        {'id' => 1, 'label' => 'chicken', 'load_board' => {'id' => ref['id'], 'url' => "http://www.board.com/example", 'data_url' => "http://www.board.com/api/example"}}
      ]
      b['grid'] = {
        'rows' => 2,
        'columns' => 2,
        'order' => [[1,nil], [nil, nil]]
      }
      file = Tempfile.new("stash")
      OBF::External.to_obf(b, file.path)
      json = JSON.parse(file.read)
      file.unlink
      expect(json['id']).to eq(b['id'])
      expect(json['name']).to eq('My Board')
      expect(json['default_layout']).to eq('landscape')
      expect(json['url']).to eq("http://www.boards.com/example")
      expect(json['grid']).to eq({
        'rows' => 2,
        'columns' => 2,
        'order' => [[1, nil], [nil, nil]]
      })
      expect(json['buttons'].length).to eq(1)
      expect(json['buttons'][0]).to eq({
        'id' => 1,
        'label' => 'chicken', 
        'vocalization' => nil,
        'left' => nil,
        'top' => nil,
        'load_board' => {
          'id' => ref['id'], 
          'url' => "http://www.board.com/example", 
          'data_url' => "http://www.board.com/api/example"
        },
        'width' => nil,
        'height' => nil,
        'border_color' => '#aaa',
        'background_color' => '#fff'
      })
    end
    
    it "should include images and sounds inline" do
      res = OpenStruct.new(:success? => true, :body => "abc", :headers => {'Content-Type' => 'text/plaintext'})
      expect(Typhoeus).to receive(:get).with("http://example.com/pic.png").and_return(res)
      expect(Typhoeus).to receive(:get).with("http://example.com/sound.mp3").and_return(res)
      ref = external_board
      b = external_board
      b['name'] = "My Board"
      b['images'] = [{
        'id' => '123',
        'url' => "http://example.com/pic.png", 
        'data_url' => "http://www.example.com/api/pic",
        'content_type' => 'text/plaintext'
      }]
      b['sounds'] = [{
        'id' => '234',
        'url' => "http://example.com/sound.mp3", 
        'content_type' => 'text/plaintext'
      }]
      b['buttons'] = [
        {'id' => 1, 'label' => 'chicken', 'image_id' => b['images'][0]['id'], 'sound_id' => b['sounds'][0]['id']}
      ]
      b['grid'] = {
        'rows' => 2,
        'columns' => 2,
        'order' => [[1,nil]]
      }
      file = Tempfile.new("stash")
      OBF::External.to_obf(b, file.path)
      json = JSON.parse(file.read)
      file.unlink
      expect(json['id']).to eq(b['id'])
      expect(json['name']).to eq('My Board')
      expect(json['default_layout']).to eq('landscape')
      expect(json['url']).to eq("http://www.boards.com/example")
      list = []
      list << {
        'id' => b['images'][0]['id'],
        'width' => nil,
        'height' => nil,
        'license' => {'type' => 'private'},
        'url' => 'http://example.com/pic.png',
        'data_url' => "http://www.example.com/api/pic",
        'content_type' => 'text/plaintext',
        'data' => 'data:text/plaintext;base64,YWJj'
      }
      expect(json['images']).to eq(list)

      list = []
      list << {
        'id' => b['sounds'][0]['id'],
        'duration' => nil,
        'license' => {'type' => 'private'},
        'url' => 'http://example.com/sound.mp3',
        'data_url' => nil,
        'content_type' => 'text/plaintext',
        'data' => 'data:text/plaintext;base64,YWJj'
      }
      expect(json['sounds']).to eq(list)
    end
    
    it "should not include superfluous sounds or images"
    
    it "should export links to external urls" do
      b = external_board
      b['name'] = "My Board"
      b['buttons'] = [
        {'id' => 1, 'label' => 'chicken', 'url' => 'http://www.example.com'}
      ]
      b['grid'] = {
        'rows' => 2,
        'columns' => 2,
        'order' => [[1,nil],[nil,nil]]
      }
      file = Tempfile.new("stash")
      OBF::External.to_obf(b, file.path)
      json = JSON.parse(file.read)
      file.unlink
      expect(json['id']).to eq(b['id'])
      expect(json['name']).to eq('My Board')
      expect(json['default_layout']).to eq('landscape')
      expect(json['url']).to eq("http://www.boards.com/example")
      expect(json['grid']).to eq({
        'rows' => 2,
        'columns' => 2,
        'order' => [[1, nil], [nil, nil]]
      })
      expect(json['buttons'].length).to eq(1)
      expect(json['buttons'][0]).to eq({
        'id' => 1,
        'label' => 'chicken', 
        'vocalization' => nil,
        'left' => nil,
        'top' => nil,
        'width' => nil,
        'height' => nil,
        'border_color' => '#aaa',
        'background_color' => '#fff',
        'url' => 'http://www.example.com'
      })
    end
    
    it "should export links to external apps" do
      b = external_board
      b['name'] = "My Board"
      b['buttons'] = [
        {'id' => 1, 'label' => 'chicken', 'ext_coughdrop_apps' => {'web' => {'launch_url' => 'http://www.example.com'}}}
      ]
      b['grid'] = {
        'rows' => 2,
        'columns' => 2,
        'order' => [[1,nil],[nil,nil]]
      }
      file = Tempfile.new("stash")
      OBF::External.to_obf(b, file.path)
      json = JSON.parse(file.read)
      file.unlink
      expect(json['id']).to eq(b['id'])
      expect(json['name']).to eq('My Board')
      expect(json['default_layout']).to eq('landscape')
      expect(json['url']).to eq("http://www.boards.com/example")
      expect(json['grid']).to eq({
        'rows' => 2,
        'columns' => 2,
        'order' => [[1, nil], [nil, nil]]
      })
      expect(json['buttons'].length).to eq(1)
      expect(json['buttons'][0]).to eq({
        'id' => 1,
        'label' => 'chicken', 
        'vocalization' => nil,
        'left' => nil,
        'top' => nil,
        'width' => nil,
        'height' => nil,
        'border_color' => '#aaa',
        'background_color' => '#fff',
        'ext_coughdrop_apps' =>  {'web' => {'launch_url' => 'http://www.example.com'}}
      })
    end
  end

  describe "from_obf" do
    it "should parse from a file" do
      path = OBF::Utils.temp_path("stash")
      shell = OBF::Utils.obf_shell
      shell['id'] = '2345'
      shell['name'] = "Cool Board"
      File.open(path, 'w') do |f|
        f.puts shell.to_json
      end
      b = OBF::External.from_obf(path, {})
      expect(b).not_to eql(nil)
      expect(b['id']).to eql('2345')
      expect(b['name']).to eq("Cool Board")
    end
    
    it "should parse from a hash" do
      shell = OBF::Utils.obf_shell
      shell['id'] = '1234'
      shell['name'] = "Cool Board"
      b = OBF::External.from_obf(shell, {})
      expect(b).not_to eql(nil)
      expect(b['id']).to eql('1234')
      expect(b['name']).to eq("Cool Board")
    end
    
    it "should retrieve images and sounds from the zip file"
    
    it "should import external url links" do
      path = OBF::Utils.temp_path("stash")
      shell = OBF::Utils.obf_shell
      shell['id'] = '2345'
      shell['name'] = "Cool Board"
      shell['buttons'] = [{
        'id' => '1',
        'label' => 'hardly',
        'url' => 'http://www.example.com'
      }]
      File.open(path, 'w') do |f|
        f.puts shell.to_json
      end
      b = OBF::External.from_obf(path, {})
      expect(b).not_to eql(nil)
      expect(b['id']).to eql('2345')
      expect(b['name']).to eq("Cool Board")
      button = b['buttons'][0]
      expect(button).not_to eq(nil)
      expect(button['url']).to eq('http://www.example.com')
    end
    
    it "should import external app links" do
      path = OBF::Utils.temp_path("stash")
      shell = OBF::Utils.obf_shell
      shell['id'] = '2345'
      shell['name'] = "Cool Board"
      shell['buttons'] = [{
        'id' => '1',
        'label' => 'hardly',
        'url' => 'http://www.example.com',
        'ext_coughdrop_apps' => {
          'a' => 1
        }
      }]
      File.open(path, 'w') do |f|
        f.puts shell.to_json
      end
      b = OBF::External.from_obf(path, {})
      expect(b).not_to eql(nil)
      expect(b['name']).to eq("Cool Board")
      button = b['buttons'][0]
      expect(button).not_to eq(nil)
      expect(button['url']).to eq('http://www.example.com')
      expect(button['ext_coughdrop_apps']).to eq({'a' => 1})
    end
    
  end

  describe "to_obz" do
    it "should build without errors" do
      b = external_board
      b2 = external_board
      b['buttons'] = [{
        'id' => '1', 'load_board' => {'id' => b2['id']}
      }]
      b['grid'] = {
        'rows' => 1,
        'columns' => 1,
        'order' => [['1']]
      }
      path = OBF::Utils.temp_path("stash")
      OBF::External.to_obz({'boards' => [b]}, path, {})
      expect(File.exist?(path)).to eq(true)
      expect(File.size(path)).to be > 10
    end
    
    it "should include linked boards" do
      b = external_board
      b2 = external_board
      b['buttons'] = [{
        'id' => '1', 'load_board' => {'id' => b2['id']}
      }]
      b['grid'] = {
        'rows' => 1,
        'columns' => 1,
        'order' => [['1']]
      }
      path = OBF::Utils.temp_path("stash")
      OBF::External.to_obz({'boards' => [b, b2]}, path, {})
      expect(File.exist?(path)).to eq(true)
      expect(File.size(path)).to be > 10
      
      OBF::Utils.load_zip(path) do |zipper|
        manifest = JSON.parse(zipper.read('manifest.json'))
        expect(manifest['root']).not_to eq(nil)
        board = JSON.parse(zipper.read(manifest['root'])) rescue nil
        expect(board).not_to eq(nil)
        expect(board['buttons']).not_to eq(nil)
        expect(board['buttons'][0]).not_to eq(nil)
        expect(board['buttons'][0]['load_board']['path']).not_to eq(nil)
        board2 = JSON.parse(zipper.read(board['buttons'][0]['load_board']['path'])) rescue nil
        expect(board2).not_to eq(nil)
      end
    end

    it "should include images" do
      res = OpenStruct.new(:success? => true, :body => "abc", :headers => {'Content-Type' => 'text/plaintext'})
      expect(Typhoeus).to receive(:get).with("http://example.com/pic.png").and_return(res)
      expect(Typhoeus).to receive(:get).with("http://example.com/sound.mp3").and_return(res)
      ref = external_board
      b = external_board
      b['name'] = "My Board"
      b['images'] = [{
        'id' => '123',
        'url' => "http://example.com/pic.png",
        'content_type' => 'text/plaintext'
      }]
      b['sounds'] = [{
        'id' => '234',
        'url' => "http://example.com/sound.mp3",
        'content_type' => 'text/plaintext'
      }]
      b['buttons'] = [
        {'id' => 1, 'label' => 'chicken', 'image_id' => b['images'][0]['id'], 'sound_id' => b['sounds'][0]['id']}
      ]
      b['grid'] = {
        'rows' => 2,
        'columns' => 2,
        'order' => [[1,nil]]
      }

      path = OBF::Utils.temp_path("stash")
      OBF::External.to_obz({'boards' => [b]}, path, {})
      
      OBF::Utils.load_zip(path) do |zipper|
        manifest = JSON.parse(zipper.read('manifest.json'))
        json = JSON.parse(zipper.read(manifest['root']))
        expect(json['id']).to eq(b['id'])
        expect(json['name']).to eq('My Board')
        expect(json['default_layout']).to eq('landscape')
        expect(json['url']).to eq("http://www.boards.com/example")
        list = []
        list << {
          'id' => b['images'][0]['id'],
          'width' => nil,
          'height' => nil,
          'license' => {'type' => 'private'},
          'url' => 'http://example.com/pic.png',
          'data_url' => nil,
          'content_type' => 'text/plaintext',
          'path' => "images/image_#{b['images'][0]['id']}"
        }
        expect(json['images']).to eq(list)

        list = []
        list << {
          'id' => b['sounds'][0]['id'],
          'duration' => nil,
          'license' => {'type' => 'private'},
          'url' => 'http://example.com/sound.mp3',
          'data_url' => nil,
          'content_type' => 'text/plaintext',
          'path' => "sounds/sound_#{b['sounds'][0]['id']}"
        }
        expect(json['sounds']).to eq(list)
      end
    end
  end

  describe "from_obz" do
    it "should parse" do
      b = external_board
      b2 = external_board
      b['buttons'] = [{
        'id' => '1', 'load_board' => {'id' => b2['id']}
      }]
      b['grid'] = {
        'rows' => 1,
        'columns' => 1,
        'order' => [['1']]
      }
      path = OBF::Utils.temp_path("stash")
      OBF::External.to_obz({'boards' => [b, b2]}, path, {})
      expect(File.exist?(path)).to eq(true)
      expect(File.size(path)).to be > 10
      
      boards = OBF::External.from_obz(path, {})['boards']
      expect(boards).not_to eq(nil)
      expect(boards.length).to eq(2)
      expect(boards[0]['id']).to eq(b['id'])
      expect(boards[1]['id']).to eq(b2['id'])
    end
    
    it "should return a list of unique images"
    it "should return a list of unique sounds"
  end

  describe "to_pdf" do
    it "should convert to pdf, then use the obf-to-pdf converter" do
      expect(OBF::External).to receive(:to_obf).and_return("/file.obf")
      expect(OBF::OBF).to receive(:to_pdf) do |tmp, dest|
        expect(tmp).not_to eq(nil)
        expect(dest).to eq("/file.pdf")
      end
      OBF::External.to_pdf(nil, "/file.pdf", {})
    end
    
    it "if specified it should use obz instead of obf as the middle step" do
      expect(OBF::External).to receive(:to_obz).and_return("/file.obz")
      expect(OBF::OBZ).to receive(:to_pdf) do |tmp, dest|
        expect(tmp).not_to eq(nil)
        expect(dest).to eq("/file.pdf")
      end
      OBF::External.to_pdf(nil, "/file.pdf", {'packet' => true})
    end
  end

  describe "to_png" do
    it "should convert to pdf then use the pdf-to-png converter" do
      expect(OBF::External).to receive(:to_pdf).and_return("/file.pdf")
      expect(OBF::PDF).to receive(:to_png) do |tmp, dest|
        expect(tmp).not_to eq(nil)
        expect(dest).to eq("/file.png")
      end
      OBF::External.to_png(nil, "/file.png")
    end
  end
end
