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
      expect(OBF::PDF).to receive(:from_obz).with("/file.obz", "/file.pdf")
      OBF::PDF.from_external({'boards' => []}, "/file.pdf")
    end
    
    it "should convert to obf if a single record and then render that" do
      expect(OBF::OBF).to receive(:from_external).and_return("/file.obf")
      expect(OBF::PDF).to receive(:from_obf).with("/file.obf", "/file.pdf")
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
