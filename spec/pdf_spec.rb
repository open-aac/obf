require 'spec_helper'

describe OBF::PDF do
  describe "from_obf" do
    it "should render a basic obf" do
      f = Tempfile.new("stash")
      f.puts OBF::Utils.obf_shell.to_json
      f.rewind
      f2 = Tempfile.new("stash")
      OBF::PDF.from_obf(f.path, f2.path)
      f.unlink
      f2.rewind
      expect(f2.size).to be > 2400
      f2.unlink
    end

    it "should render a basic obf with international characters" do
      f = Tempfile.new("stash")
      hash = OBF::Utils.obf_shell
      hash['buttons'] << {'id' => '1', 'label' => 'صرخة'}
      hash['grid']['rows'] = 1
      hash['grid']['columns'] = 1
      hash['grid']['order'] = [['1']]
      f.puts hash.to_json
      f.rewind
      f2 = Tempfile.new("stash")
      OBF::PDF.from_obf(f.path, f2.path)
      f.unlink
      f2.rewind
      expect(f2.size).to be > 2400
      f2.unlink
    end

    it "should render a foreign obf" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      f2 = Tempfile.new("stash")
      OBF::PDF.from_obf("./spec/samples/foreign.obf", path2)
#      `open #{path2}`
      File.unlink path2
    end
  end

  describe "from_obz" do
    it "should render a multi-page obz" do
      b1 = external_board
      b2 = external_board
      b1['buttons'] = [{
        'id' => '1', 'load_board' => {'id' => b2['id']}
      }]
      b1['grid'] = {
        'rows' => 1,
        'columns' => 1,
        'order' => [['1']]
      }
      path1 = OBF::Utils.temp_path("stash")
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      OBF::External.to_obz({'boards' => [b1, b2]}, path1, {})
      OBF::PDF.from_obz(path1, path2)
      File.unlink path1
      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be > 10
      File.unlink path2
    end

    it "should render a headerless multi-page obz" do
      b1 = external_board
      b2 = external_board
      b1['buttons'] = [{
        'id' => '1', 'load_board' => {'id' => b2['id']}, 'label' => 'fish'
      }]
      b1['grid'] = {
        'rows' => 1,
        'columns' => 1,
        'order' => [['1']]
      }
      path1 = OBF::Utils.temp_path("stash")
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      OBF::External.to_obz({'boards' => [b1, b2]}, path1, {})
      OBF::PDF.from_obz(path1, path2, {'headerless' => true})
      File.unlink path1
      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be > 10
#      `open #{path2}`
      File.unlink path2
    end
    
    it "should render a text_on_top multi-page obz" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      OBF::PDF.from_obf('./spec/samples/inline_images.obf', path2, nil, {'text_on_top' => true})
      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be > 20000
#      `open #{path2}`
      File.unlink path2
    end

    it "should render a text_on_top multi-page obz" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      
      expect(OBF::Utils).to receive(:save_image){|img, zipper, bg|
        expect(img['data']).to_not eq(nil)
        if img['id'] == 99
          expect(bg).to eq('#ffffff')
        else
          expect(bg).to eq('#80ff80')
        end
      }.exactly(4).times.and_return(nil)
      OBF::PDF.from_obf('./spec/samples/inline_images.obf', path2, nil, {'transparent_background' => true})

      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be < 30000
#     `open #{path2}`
      File.unlink path2
    end
    
    it "should render a multi-page pre-generated obz" do
      path2 = OBF::Utils.temp_path(["file", ".pdf"])
      expect(OBF::PDF).to receive(:build_page).exactly(3).times
      OBF::PDF.from_obz('./spec/samples/links.obz', path2)
      expect(File.exist?(path2)).to eq(true)
      expect(File.size(path2)).to be > 10
#      `open #{path2}`
      File.unlink path2
    end

  end

  describe "from_coughdrop" do
    it "should convert to obz and then render that" do
      expect(OBF::OBZ).to receive(:from_external).and_return("/file.obz")
      expect(OBF::PDF).to receive(:from_obz).with("/file.obz", "/file.pdf", {})
      OBF::PDF.from_external({'boards' => []}, "/file.pdf")
    end
    
    it "should convert to obf if a single record and then render that" do
      expect(OBF::OBF).to receive(:from_external).and_return("/file.obf")
      expect(OBF::PDF).to receive(:from_obf).with("/file.obf", "/file.pdf", nil, {})
      OBF::PDF.from_external({}, "/file.pdf")
    end
  end  

  describe "to_png" do
    it "should use the png-from-pdf converter" do
      file = "/file.pdf"
      path = "/file.png"
      expect(OBF::PNG).to receive(:from_pdf).with(file, path)
      OBF::PDF.to_png(file, path)
    end
  end

  it "should generate from data-uris" do
    json = <<~HEREDOC
      {
        "format": "open-board-0.1",
        "license": {
          "type": "CC By",
          "copyright_notice_url": "http://creativecommons.org/licenses/by/4.0/",
          "author_name": "CoughDrop",
          "author_url": "https://www.mycoughdrop.com/example"
        },
        "buttons": [{
          "id": 1,
          "label": "I",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5985_7880dac7be2d44f8898e5f6a"
        }],
        "grid": {
          "rows": 6,
          "columns": 10,
          "order": [
            [1, 2, 3, 10, 41, 5, 20, 7, 40, 42],
            [8, 9, 4, 44, 11, 19, 6, 14, 43, 45],
            [15, 16, 17, 26, 24, 50, 13, 46, 47, 21],
            [23, 22, 25, 18, 12, 29, 28, 53, 52, 54],
            [30, 31, 32, 49, 39, 27, 34, 33, 55, 48],
            [35, 37, 36, 51, 56, 57, 58, 59, 60, 38]
          ]
        },
        "images": [{
          "id": "1_5985_7880dac7be2d44f8898e5f6a",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "data": "data:image/png;base64,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",
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/I.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5985_7880dac7be2d44f8898e5f6a",
          "content_type": null
        }],
        "sounds": [],
        "id": "1_416",
        "name": "Quick Core 60",
        "locale": "en",
        "default_layout": "landscape",
        "url": "https://app.mycoughdrop.com/example/core-60",
        "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60",
        "ext_coughdrop_settings": {
          "private": false,
          "key": "example/core-60",
          "word_suggestions": false,
          "protected": false,
          "home_board": true,
          "categories": ["robust"],
          "text_only": null,
          "hide_empty": false
        }
      }
      HEREDOC
      OBF::PDF.from_external(JSON.parse(json), "./file.pdf", {'headerless' => true, 'text_on_top' => true, 'symbol_background' => 'transparent'})
      `open ./file.pdf`
    end

  it "should pdf" do
    json = <<~HEREDOC
      {
        "format": "open-board-0.1",
        "license": {
          "type": "CC By",
          "copyright_notice_url": "http://creativecommons.org/licenses/by/4.0/",
          "author_name": "CoughDrop",
          "author_url": "https://www.mycoughdrop.com/example"
        },
        "buttons": [{
          "id": 1,
          "label": "I",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5985_7880dac7be2d44f8898e5f6a"
        }, {
          "id": 2,
          "label": "me",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1161",
            "url": "https://app.mycoughdrop.com/example/core-60-me",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-me"
          },
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5995_2c873ca63facc90a2f3bba93"
        }, {
          "id": 3,
          "label": "do",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1150",
            "url": "https://app.mycoughdrop.com/example/core-60-do",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-do"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_5996_f269037aa2c3fe0716793d0f"
        }, {
          "id": 10,
          "label": "want",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_5999_b2904b007b209b41b5ee03cb"
        }, {
          "id": 41,
          "label": "like",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_287437_6da512bb667ab540414dc4cf"
        }, {
          "id": 5,
          "label": "eat",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1149",
            "url": "https://app.mycoughdrop.com/example/core-60-eat",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-eat"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_5998_6101790464fdbbabafa90b5b"
        }, {
          "id": 20,
          "label": "to",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(204, 204, 204)",
          "background_color": "rgb(255, 255, 255)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "preposition",
          "image_id": "1_6079_c9013e57096cc1a36fdbe57e"
        }, {
          "id": 7,
          "label": "good",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(17, 112, 255)",
          "background_color": "rgb(170, 204, 255)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "adjective",
          "image_id": "1_6025_4dfa3b6d920494c01d6b3c0d"
        }, {
          "id": 40,
          "label": "on",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(17, 112, 255)",
          "background_color": "rgb(170, 204, 255)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "adverb",
          "image_id": "1_6034_54ef01ee966add4d75055149"
        }, {
          "id": 42,
          "label": "in",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(17, 112, 255)",
          "background_color": "rgb(170, 204, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_159840",
            "url": "https://app.mycoughdrop.com/example/core-60-things-at-home",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-things-at-home"
          },
          "ext_coughdrop_part_of_speech": "adverb",
          "image_id": "1_6038_50cf4aa09d3f8e7a22cde902"
        }, {
          "id": 8,
          "label": "you",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5986_4182e77bd9fc9a0bd9aed33a"
        }, {
          "id": 9,
          "label": "we",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5989_1804814b65ba325f3593d632"
        }, {
          "id": 4,
          "label": "go",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1151",
            "url": "https://app.mycoughdrop.com/example/core-60-go",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-go"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_5997_0687f9dfa1578b5a07634110"
        }, {
          "id": 44,
          "label": "help",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_159817",
            "url": "https://app.mycoughdrop.com/example/core-60-help",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-help"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_287438_f7f64f7430aa6565c065a724"
        }, {
          "id": 11,
          "label": "tell",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_14260",
            "url": "https://app.mycoughdrop.com/example/core-60-tell",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-tell"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_14931_2920ffa7054ebdd0793e03d8"
        }, {
          "id": 19,
          "label": "feel",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1162",
            "url": "https://app.mycoughdrop.com/example/core-60-feel",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-feel"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_6069_387673bdcd6b1c031b1854e0"
        }, {
          "id": 6,
          "label": "that",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(128, 128, 128)",
          "background_color": "rgb(204, 204, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "determiner",
          "image_id": "1_6008_72103349326817897c938972"
        }, {
          "id": 14,
          "label": "bad",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(17, 112, 255)",
          "background_color": "rgb(170, 204, 255)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "adjective",
          "image_id": "1_6026_0ca4d040ddcd15ee97a4e3b3"
        }, {
          "id": 43,
          "label": "off",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(17, 112, 255)",
          "background_color": "rgb(170, 204, 255)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "adverb",
          "image_id": "1_6035_e05f5045bc43d624cbf6d1d1"
        }, {
          "id": 45,
          "label": "out",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(17, 112, 255)",
          "background_color": "rgb(170, 204, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_159841",
            "url": "https://app.mycoughdrop.com/example/core-60-outdoors",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-outdoors"
          },
          "ext_coughdrop_part_of_speech": "adverb",
          "image_id": "1_6039_db35f58d28122fc473592857"
        }, {
          "id": 15,
          "label": "he",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5987_14e86f8599c9b22b9ac96609"
        }, {
          "id": 16,
          "label": "she",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5988_7af1676aae6b31e58cc8d839"
        }, {
          "id": 17,
          "label": "is",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1152",
            "url": "https://app.mycoughdrop.com/example/core-60-is",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-is"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_6002_961d7202802caf628b966ef3"
        }, {
          "id": 26,
          "label": "need",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_41441",
            "url": "https://app.mycoughdrop.com/example/core-60-need",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-need"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_14933_f5abcca1018836a08488ee84"
        }, {
          "id": 24,
          "label": "know",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1163",
            "url": "https://app.mycoughdrop.com/example/core-60-know",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-know"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_14760_5adee593f70009e7e6b9025f"
        }, {
          "id": 50,
          "label": "not",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 17, 17)",
          "background_color": "rgb(255, 170, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "negation",
          "image_id": "1_6042_3f4594443ab0f1b0516fccff"
        }, {
          "id": 13,
          "label": "this",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(128, 128, 128)",
          "background_color": "rgb(204, 204, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "determiner",
          "image_id": "1_6010_6a2eefd211057348e6452908"
        }, {
          "id": 46,
          "label": "some",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(128, 128, 128)",
          "background_color": "rgb(204, 204, 204)",
          "hidden": false,
          "load_board": {
            "id": "1_159850",
            "url": "https://app.mycoughdrop.com/example/core-60-snacks-and-treats",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-snacks-and-treats"
          },
          "ext_coughdrop_part_of_speech": "determiner",
          "image_id": "1_6044_51cf4f9d638ef07babba9cfe"
        }, {
          "id": 47,
          "label": "more",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(128, 128, 128)",
          "background_color": "rgb(204, 204, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "determiner",
          "image_id": "1_6033_d0e46faf924282781e7a49e9"
        }, {
          "id": 21,
          "label": "here",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(17, 112, 255)",
          "background_color": "rgb(170, 204, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_1189",
            "url": "https://app.mycoughdrop.com/example/core-60-here",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-here"
          },
          "ext_coughdrop_part_of_speech": "adverb",
          "image_id": "1_15336_17e6a8da9fd7086031d04355"
        }, {
          "id": 23,
          "label": "they",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1154",
            "url": "https://app.mycoughdrop.com/example/core-60-they",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-they"
          },
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5990_7338c07918a83e8f6583ad61"
        }, {
          "id": 22,
          "label": "it",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(221, 221, 0)",
          "background_color": "rgb(255, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1164",
            "url": "https://app.mycoughdrop.com/example/core-60-it",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-it"
          },
          "ext_coughdrop_part_of_speech": "pronoun",
          "image_id": "1_5991_70e4bb6a12cdda28b3740c5f"
        }, {
          "id": 25,
          "label": "use",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1165",
            "url": "https://app.mycoughdrop.com/example/core-60-use",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-use"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_14762_1a22cf0d189aeb08d5915e8a"
        }, {
          "id": 18,
          "label": "look",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1153",
            "url": "https://app.mycoughdrop.com/example/core-60-look",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-look"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_6003_e62fd8edb3fe8ebfdeff2b27"
        }, {
          "id": 12,
          "label": "wear",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1148",
            "url": "https://app.mycoughdrop.com/example/core-60-wear",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-wear"
          },
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_6068_b3834cbfeb93c05f40663399"
        }, {
          "id": 29,
          "label": "the",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(128, 128, 128)",
          "background_color": "rgb(204, 204, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "article",
          "image_id": "1_6046_92a7eeaa5aa4be1d933a605d"
        }, {
          "id": 28,
          "label": "a",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(128, 128, 128)",
          "background_color": "rgb(204, 204, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "article",
          "image_id": "1_6019_23b45f12a6cd5ae0e142c158"
        }, {
          "id": 53,
          "label": "these",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(128, 128, 128)",
          "background_color": "rgb(204, 204, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "determiner",
          "image_id": "1_6049_4bcd96875e38f9d6d6bcddad"
        }, {
          "id": 52,
          "label": "those",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(128, 128, 128)",
          "background_color": "rgb(204, 204, 204)",
          "hidden": false,
          "load_board": {
            "id": "1_1191",
            "url": "https://app.mycoughdrop.com/example/core-60-those",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-those"
          },
          "ext_coughdrop_part_of_speech": "determiner",
          "image_id": "1_6048_f2b26b6418281b5449cf5a9b"
        }, {
          "id": 54,
          "label": "there",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(17, 112, 255)",
          "background_color": "rgb(170, 204, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_1190",
            "url": "https://app.mycoughdrop.com/example/core-60-there",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-there"
          },
          "ext_coughdrop_part_of_speech": "adverb",
          "image_id": "1_15337_e882112fe0808876c9fc28a9"
        }, {
          "id": 30,
          "label": "what",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(112, 17, 255)",
          "background_color": "rgb(204, 170, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_1155",
            "url": "https://app.mycoughdrop.com/example/core-60-what",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-what"
          },
          "ext_coughdrop_part_of_speech": "question",
          "image_id": "1_6030_49aaf8ce43ad241b123883be"
        }, {
          "id": 31,
          "label": "who",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(112, 17, 255)",
          "background_color": "rgb(204, 170, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_1157",
            "url": "https://app.mycoughdrop.com/example/core-60-who",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-who"
          },
          "ext_coughdrop_part_of_speech": "question",
          "image_id": "1_6070_2e6bf90bfc8ac6d2b199b1bd"
        }, {
          "id": 32,
          "label": "when",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(112, 17, 255)",
          "background_color": "rgb(204, 170, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_1156",
            "url": "https://app.mycoughdrop.com/example/core-60-when",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-when"
          },
          "ext_coughdrop_part_of_speech": "question",
          "image_id": "1_6029_bea17528697d5a9cc96fd450"
        }, {
          "id": 49,
          "label": "where",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(112, 17, 255)",
          "background_color": "rgb(204, 170, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_1158",
            "url": "https://app.mycoughdrop.com/example/core-60-where",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-where"
          },
          "ext_coughdrop_part_of_speech": "question",
          "image_id": "1_6071_227135f253e68c1bfd61b575"
        }, {
          "id": 39,
          "label": "stop",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(102, 221, 0)",
          "background_color": "rgb(204, 255, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_6031_9609db6fc7c484b290d3edeb"
        }, {
          "id": 27,
          "label": "with",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(204, 204, 204)",
          "background_color": "rgb(255, 255, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_41442",
            "url": "https://app.mycoughdrop.com/example/core-60-with",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-with"
          },
          "ext_coughdrop_part_of_speech": "preposition",
          "image_id": "1_6017_f7b1beb8cdfe1bd6430ff0b4"
        }, {
          "id": 34,
          "label": "and",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(204, 204, 204)",
          "background_color": "rgb(255, 255, 255)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "conjunction",
          "image_id": "1_6020_0c658da00d93827871c893c8"
        }, {
          "id": 33,
          "label": "of",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(204, 204, 204)",
          "background_color": "rgb(255, 255, 255)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "preposition",
          "image_id": "1_6018_8a95c22e7d9d8f30777f6cca"
        }, {
          "id": 55,
          "label": "because",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(204, 204, 204)",
          "background_color": "rgb(255, 255, 255)",
          "hidden": false,
          "load_board": {
            "id": "1_14436",
            "url": "https://app.mycoughdrop.com/example/core-60-because",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-because"
          },
          "ext_coughdrop_part_of_speech": "conjunction",
          "image_id": "1_6051_6941e9bd36046b3c6f54b573"
        }, {
          "id": 48,
          "label": "color/visual",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 112, 17)",
          "background_color": "rgb(255, 204, 170)",
          "hidden": false,
          "load_board": {
            "id": "1_1159",
            "url": "https://app.mycoughdrop.com/example/core-60-color",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-color"
          },
          "ext_coughdrop_part_of_speech": "noun",
          "image_id": "1_14665_6e18ef39b61f3f3ad2a04874"
        }, {
          "id": 35,
          "label": "yes",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(5, 163, 0)",
          "background_color": "rgb(94, 255, 102)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "social",
          "image_id": "1_5992_afb207a46ff12bf92a4a6a2e"
        }, {
          "id": 37,
          "label": "done",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(0, 97, 161)",
          "background_color": "rgb(115, 204, 255)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_554918_e4c7fe05e055b2ebaeab8516"
        }, {
          "id": 36,
          "label": "no",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 112, 112)",
          "background_color": "rgb(255, 112, 112)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "negation",
          "image_id": "1_6075_b4f04bbf9650ca0425e67f1f"
        }, {
          "id": 51,
          "label": "don't",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 17, 17)",
          "background_color": "rgb(255, 170, 170)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "verb",
          "image_id": "1_6041_aa80a1213ea2d818a936e896"
        }, {
          "id": 56,
          "label": "please",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 17, 112)",
          "background_color": "rgb(255, 170, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "social",
          "image_id": "1_6052_e33692c3afd9924a281936a9"
        }, {
          "id": 57,
          "label": "thank you",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 17, 112)",
          "background_color": "rgb(255, 170, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "social",
          "image_id": "1_6058_f04c1b36cd010636c4cde6c7"
        }, {
          "id": 58,
          "label": "hello",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 17, 112)",
          "background_color": "rgb(255, 170, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "social",
          "image_id": "1_6056_9bdd8bbeba483db7d29abf0c"
        }, {
          "id": 59,
          "label": "goodbye",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 17, 112)",
          "background_color": "rgb(255, 170, 204)",
          "hidden": false,
          "ext_coughdrop_part_of_speech": "social",
          "image_id": "1_6054_6afebe33cf4a37faa1de4665"
        }, {
          "id": 60,
          "label": "okay",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 17, 112)",
          "background_color": "rgb(255, 170, 204)",
          "hidden": false,
          "load_board": {
            "id": "1_1160",
            "url": "https://app.mycoughdrop.com/example/core-60-okay",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60-okay"
          },
          "ext_coughdrop_part_of_speech": "social",
          "image_id": "1_14689_b0e3a8813a588946d85f3e84"
        }, {
          "id": 38,
          "label": "keyboard",
          "left": null,
          "top": null,
          "width": null,
          "height": null,
          "border_color": "rgb(255, 112, 17)",
          "background_color": "rgb(255, 204, 170)",
          "hidden": false,
          "action": ":native-keyboard",
          "load_board": {
            "id": "1_58",
            "url": "https://app.mycoughdrop.com/example/keyboard",
            "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/keyboard"
          },
          "ext_coughdrop_part_of_speech": "noun",
          "image_id": "1_6047_7d41b9c24ccc0bb132a15c3e"
        }],
        "grid": {
          "rows": 6,
          "columns": 10,
          "order": [
            [1, 2, 3, 10, 41, 5, 20, 7, 40, 42],
            [8, 9, 4, 44, 11, 19, 6, 14, 43, 45],
            [15, 16, 17, 26, 24, 50, 13, 46, 47, 21],
            [23, 22, 25, 18, 12, 29, 28, 53, 52, 54],
            [30, 31, 32, 49, 39, 27, 34, 33, 55, 48],
            [35, 37, 36, 51, 56, 57, 58, 59, 60, 38]
          ]
        },
        "images": [{
          "id": "1_5985_7880dac7be2d44f8898e5f6a",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/I.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5985_7880dac7be2d44f8898e5f6a",
          "content_type": null
        }, {
          "id": "1_5995_2c873ca63facc90a2f3bba93",
          "width": null,
          "height": null,
          "protected": false,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/me.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5995_2c873ca63facc90a2f3bba93",
          "content_type": null
        }, {
          "id": "1_5996_f269037aa2c3fe0716793d0f",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/to do exercise_2.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5996_f269037aa2c3fe0716793d0f",
          "content_type": null
        }, {
          "id": "1_5999_b2904b007b209b41b5ee03cb",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/to want.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5999_b2904b007b209b41b5ee03cb",
          "content_type": null
        }, {
          "id": "1_287437_6da512bb667ab540414dc4cf",
          "width": 250,
          "height": 250,
          "protected": false,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://d18vdu4p71yql0.cloudfront.net/libraries/arasaac/to like.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_287437_6da512bb667ab540414dc4cf",
          "content_type": "image/png"
        }, {
          "id": "1_5998_6101790464fdbbabafa90b5b",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/to eat_1.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5998_6101790464fdbbabafa90b5b",
          "content_type": null
        }, {
          "id": "1_6079_c9013e57096cc1a36fdbe57e",
          "width": 851,
          "height": 851,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-sa/2.0/uk",
            "author_name": "Paxtoncrafts Charitable Trust ",
            "author_url": "http://straight-street.org/lic.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/mulberry/left.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6079_c9013e57096cc1a36fdbe57e",
          "content_type": null
        }, {
          "id": "1_6025_4dfa3b6d920494c01d6b3c0d",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/good.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6025_4dfa3b6d920494c01d6b3c0d",
          "content_type": null
        }, {
          "id": "1_6034_54ef01ee966add4d75055149",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-sa/2.0/uk",
            "author_name": "Paxtoncrafts Charitable Trust ",
            "author_url": "http://straight-street.org/lic.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/mulberry/turn on light switch , to.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6034_54ef01ee966add4d75055149",
          "content_type": null
        }, {
          "id": "1_6038_50cf4aa09d3f8e7a22cde902",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-sa/2.0/uk",
            "author_name": "Paxtoncrafts Charitable Trust ",
            "author_url": "http://straight-street.org/lic.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/mulberry/in.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6038_50cf4aa09d3f8e7a22cde902",
          "content_type": null
        }, {
          "id": "1_5986_4182e77bd9fc9a0bd9aed33a",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/you.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5986_4182e77bd9fc9a0bd9aed33a",
          "content_type": null
        }, {
          "id": "1_5989_1804814b65ba325f3593d632",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/we.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5989_1804814b65ba325f3593d632",
          "content_type": null
        }, {
          "id": "1_5997_0687f9dfa1578b5a07634110",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/to go_3.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5997_0687f9dfa1578b5a07634110",
          "content_type": null
        }, {
          "id": "1_287438_f7f64f7430aa6565c065a724",
          "width": 250,
          "height": 250,
          "protected": false,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://d18vdu4p71yql0.cloudfront.net/libraries/arasaac/help.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_287438_f7f64f7430aa6565c065a724",
          "content_type": "image/png"
        }, {
          "id": "1_14931_2920ffa7054ebdd0793e03d8",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/tell.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_14931_2920ffa7054ebdd0793e03d8",
          "content_type": null
        }, {
          "id": "1_6069_387673bdcd6b1c031b1854e0",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/to feel dizzy.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6069_387673bdcd6b1c031b1854e0",
          "content_type": null
        }, {
          "id": "1_6008_72103349326817897c938972",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/that_2.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6008_72103349326817897c938972",
          "content_type": null
        }, {
          "id": "1_6026_0ca4d040ddcd15ee97a4e3b3",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/bad_1.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6026_0ca4d040ddcd15ee97a4e3b3",
          "content_type": null
        }, {
          "id": "1_6035_e05f5045bc43d624cbf6d1d1",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-sa/2.0/uk",
            "author_name": "Paxtoncrafts Charitable Trust ",
            "author_url": "http://straight-street.org/lic.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/mulberry/off.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6035_e05f5045bc43d624cbf6d1d1",
          "content_type": null
        }, {
          "id": "1_6039_db35f58d28122fc473592857",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-sa/2.0/uk",
            "author_name": "Paxtoncrafts Charitable Trust ",
            "author_url": "http://straight-street.org/lic.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/mulberry/out.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6039_db35f58d28122fc473592857",
          "content_type": null
        }, {
          "id": "1_5987_14e86f8599c9b22b9ac96609",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/he.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5987_14e86f8599c9b22b9ac96609",
          "content_type": null
        }, {
          "id": "1_5988_7af1676aae6b31e58cc8d839",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/she.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5988_7af1676aae6b31e58cc8d839",
          "content_type": null
        }, {
          "id": "1_6002_961d7202802caf628b966ef3",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/is.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6002_961d7202802caf628b966ef3",
          "content_type": null
        }, {
          "id": "1_14933_f5abcca1018836a08488ee84",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-sa/2.0/uk",
            "author_name": "Paxtoncrafts Charitable Trust ",
            "author_url": "http://straight-street.org/lic.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/mulberry/need toilet.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_14933_f5abcca1018836a08488ee84",
          "content_type": null
        }, {
          "id": "1_14760_5adee593f70009e7e6b9025f",
          "width": 250,
          "height": 250,
          "protected": false,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/to know.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_14760_5adee593f70009e7e6b9025f",
          "content_type": null
        }, {
          "id": "1_6042_3f4594443ab0f1b0516fccff",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/Not wanting to.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6042_3f4594443ab0f1b0516fccff",
          "content_type": null
        }, {
          "id": "1_6010_6a2eefd211057348e6452908",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/this.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6010_6a2eefd211057348e6452908",
          "content_type": null
        }, {
          "id": "1_6044_51cf4f9d638ef07babba9cfe",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/some_1.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6044_51cf4f9d638ef07babba9cfe",
          "content_type": null
        }, {
          "id": "1_6033_d0e46faf924282781e7a49e9",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-sa/2.0/uk",
            "author_name": "Paxtoncrafts Charitable Trust ",
            "author_url": "http://straight-street.org/lic.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/mulberry/more.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6033_d0e46faf924282781e7a49e9",
          "content_type": null
        }, {
          "id": "1_15336_17e6a8da9fd7086031d04355",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/here_1.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_15336_17e6a8da9fd7086031d04355",
          "content_type": null
        }, {
          "id": "1_5990_7338c07918a83e8f6583ad61",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/they.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5990_7338c07918a83e8f6583ad61",
          "content_type": null
        }, {
          "id": "1_5991_70e4bb6a12cdda28b3740c5f",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/it.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5991_70e4bb6a12cdda28b3740c5f",
          "content_type": null
        }, {
          "id": "1_14762_1a22cf0d189aeb08d5915e8a",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/use.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_14762_1a22cf0d189aeb08d5915e8a",
          "content_type": null
        }, {
          "id": "1_6003_e62fd8edb3fe8ebfdeff2b27",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/look at - watch.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6003_e62fd8edb3fe8ebfdeff2b27",
          "content_type": null
        }, {
          "id": "1_6068_b3834cbfeb93c05f40663399",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/clothes.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6068_b3834cbfeb93c05f40663399",
          "content_type": null
        }, {
          "id": "1_6046_92a7eeaa5aa4be1d933a605d",
          "width": 100,
          "height": 100,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "public domain",
            "copyright_notice_url": "http://creativecommons.org/publicdomain/mark/1.0/",
            "source_url": "http://thenounproject.com/term/point-of interest/",
            "author_name": "Unknown Designer",
            "author_url": "http://thenounproject.com",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/noun-project/Point of Interest-d99669a635.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6046_92a7eeaa5aa4be1d933a605d",
          "content_type": null
        }, {
          "id": "1_6019_23b45f12a6cd5ae0e142c158",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/a.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6019_23b45f12a6cd5ae0e142c158",
          "content_type": null
        }, {
          "id": "1_6049_4bcd96875e38f9d6d6bcddad",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/these.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6049_4bcd96875e38f9d6d6bcddad",
          "content_type": null
        }, {
          "id": "1_6048_f2b26b6418281b5449cf5a9b",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/those.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6048_f2b26b6418281b5449cf5a9b",
          "content_type": null
        }, {
          "id": "1_15337_e882112fe0808876c9fc28a9",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/there.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_15337_e882112fe0808876c9fc28a9",
          "content_type": null
        }, {
          "id": "1_6030_49aaf8ce43ad241b123883be",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/what.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6030_49aaf8ce43ad241b123883be",
          "content_type": null
        }, {
          "id": "1_6070_2e6bf90bfc8ac6d2b199b1bd",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/who.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6070_2e6bf90bfc8ac6d2b199b1bd",
          "content_type": null
        }, {
          "id": "1_6029_bea17528697d5a9cc96fd450",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/when.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6029_bea17528697d5a9cc96fd450",
          "content_type": null
        }, {
          "id": "1_6071_227135f253e68c1bfd61b575",
          "width": 851,
          "height": 851,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-sa/2.0/uk",
            "author_name": "Paxtoncrafts Charitable Trust ",
            "author_url": "http://straight-street.org/lic.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/mulberry/where.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6071_227135f253e68c1bfd61b575",
          "content_type": null
        }, {
          "id": "1_6031_9609db6fc7c484b290d3edeb",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc/2.0/",
            "author_name": "Sclera",
            "author_url": "http://www.sclera.be/en/picto/copyright",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/sclera/stop.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6031_9609db6fc7c484b290d3edeb",
          "content_type": null
        }, {
          "id": "1_6017_f7b1beb8cdfe1bd6430ff0b4",
          "width": null,
          "height": null,
          "protected": false,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/with.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6017_f7b1beb8cdfe1bd6430ff0b4",
          "content_type": null
        }, {
          "id": "1_6020_0c658da00d93827871c893c8",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/and.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6020_0c658da00d93827871c893c8",
          "content_type": null
        }, {
          "id": "1_6018_8a95c22e7d9d8f30777f6cca",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/of.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6018_8a95c22e7d9d8f30777f6cca",
          "content_type": null
        }, {
          "id": "1_6051_6941e9bd36046b3c6f54b573",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/because.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6051_6941e9bd36046b3c6f54b573",
          "content_type": null
        }, {
          "id": "1_14665_6e18ef39b61f3f3ad2a04874",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/Which color is it.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_14665_6e18ef39b61f3f3ad2a04874",
          "content_type": null
        }, {
          "id": "1_5992_afb207a46ff12bf92a4a6a2e",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/yes_2.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_5992_afb207a46ff12bf92a4a6a2e",
          "content_type": null
        }, {
          "id": "1_554918_e4c7fe05e055b2ebaeab8516",
          "width": 250,
          "height": 250,
          "protected": false,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://d18vdu4p71yql0.cloudfront.net/libraries/arasaac/to finish_2.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_554918_e4c7fe05e055b2ebaeab8516",
          "content_type": "image/png"
        }, {
          "id": "1_6075_b4f04bbf9650ca0425e67f1f",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/no entry.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6075_b4f04bbf9650ca0425e67f1f",
          "content_type": null
        }, {
          "id": "1_6041_aa80a1213ea2d818a936e896",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/don't touch!.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6041_aa80a1213ea2d818a936e896",
          "content_type": null
        }, {
          "id": "1_6052_e33692c3afd9924a281936a9",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/please.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6052_e33692c3afd9924a281936a9",
          "content_type": null
        }, {
          "id": "1_6058_f04c1b36cd010636c4cde6c7",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/shake hands.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6058_f04c1b36cd010636c4cde6c7",
          "content_type": null
        }, {
          "id": "1_6056_9bdd8bbeba483db7d29abf0c",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/hello.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6056_9bdd8bbeba483db7d29abf0c",
          "content_type": null
        }, {
          "id": "1_6054_6afebe33cf4a37faa1de4665",
          "width": null,
          "height": null,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/goodbye.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6054_6afebe33cf4a37faa1de4665",
          "content_type": null
        }, {
          "id": "1_14689_b0e3a8813a588946d85f3e84",
          "width": 250,
          "height": 250,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC BY-NC-SA",
            "copyright_notice_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
            "author_name": "Sergio Palao",
            "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/arasaac/ok.png",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_14689_b0e3a8813a588946d85f3e84",
          "content_type": null
        }, {
          "id": "1_6047_7d41b9c24ccc0bb132a15c3e",
          "width": 36,
          "height": 32,
          "protected": null,
          "protected_source": null,
          "license": {
            "type": "CC By 3.0",
            "copyright_notice_url": "http://creativecommons.org/licenses/by/3.0/us/",
            "source_url": "https://icomoon.io",
            "author_name": "Keyamoon",
            "author_url": "http://keyamoon.com/",
            "uneditable": true
          },
          "url": "https://s3.amazonaws.com/opensymbols/libraries/icomoon/keyboard.svg",
          "data_url": "https://app.mycoughdrop.com/api/v1/images/1_6047_7d41b9c24ccc0bb132a15c3e",
          "content_type": null
        }],
        "sounds": [],
        "id": "1_416",
        "name": "Quick Core 60",
        "locale": "en",
        "default_layout": "landscape",
        "url": "https://app.mycoughdrop.com/example/core-60",
        "data_url": "https://app.mycoughdrop.com/api/v1/boards/example/core-60",
        "ext_coughdrop_settings": {
          "private": false,
          "key": "example/core-60",
          "word_suggestions": false,
          "protected": false,
          "home_board": true,
          "categories": ["robust"],
          "text_only": null,
          "hide_empty": false
        }
      }
    HEREDOC
    OBF::PDF.from_external(JSON.parse(json), "./file.pdf", {'headerless' => true, 'text_on_top' => true, 'symbol_background' => 'transparent'})
    # `open ./file.pdf`
  end
end
