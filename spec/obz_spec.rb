require 'spec_helper'

describe OBF::OBZ do
  describe "to_external" do
    it "should use the external-from-obz converter" do
      obz = "/file.obz"
      opts = {}
      expect(OBF::External).to receive(:from_obz).with(obz, opts)
      OBF::OBZ.to_external(obz, opts)
    end
  end
  
  describe "from_external" do
    it "should use the external-to-obz converter" do
      obz = "/file.obz"
      path = "/output.obz"
      expect(OBF::External).to receive(:to_obz).with(obz, path, {'user' => nil})
      OBF::OBZ.from_external(obz, path, {'user' => nil})
    end
  end
  
  describe "to_pdf" do
    it "should use the pdf-from-obz converter" do
      obz = "/file.obz"
      path = "/file.png"
      expect(OBF::PDF).to receive(:from_obz).with(obz, path)
      OBF::OBZ.to_pdf(obz, path)
    end
  end
  
  describe "parsing" do
    it "should parse a valid .obz file" do
      res = OBF::External.from_obz('./spec/samples/deep_simple.obz', {})
      expect(res['boards'].length).to eql(97)
      b = res['boards'][0]
      expect(b['id']).to eql('page1')
      expect(b['name']).to eql('CommuniKate Top Page')
      expect(b['buttons'][0]['label']).to eql('hello')
      expect(b['buttons'][2]['label']).to eql('Chatting')
      expect(b['buttons'][2]['load_board']).to eql({
        'id' => 'chatting',
        'path' => 'boards/chatting.obf'
      })
      
      b = res['boards'][1]
      expect(b['id']).to eql('chatting')
      expect(b['name']).to eql('CommuniKate Chatting')
      expect(b['buttons'][0]['label']).to eql('Top Page')
      expect(b['buttons'][0]['load_board']).to eql({
        'id' => 'page1',
        'path' => 'boards/page1.obf'
      })
      expect(b['buttons'][1]['label']).to eql('About Me')
      expect(b['buttons'][1]['load_board']).to eql({
        'id' => 'aboutme',
        'path' => 'boards/aboutme.obf'
      })
      
      b = res['boards'].detect{|brd| brd['id'] == 'aboutme' }
      expect(b).not_to eql(nil)
      expect(b['id']).to eql('aboutme')
      expect(b['name']).to eql('CommuniKate About Me')
      expect(b['buttons'][1]['label']).to eql('Name')
      expect(b['buttons'][1]['background_color']).to eql('#c0c0c0')
      expect(b['buttons'][17]['label']).to eql('About You')
      expect(b['buttons'][17]['load_board']).to eql({
        'id' => 'aboutyou',
        'path' => 'boards/aboutyou.obf'
      })
    end
  end
end
