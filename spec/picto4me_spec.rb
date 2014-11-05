require 'spec_helper'

describe OBF::Picto4me do
  it "should process a simple linked set" do
    content = OBF::Picto4me.to_external('./spec/samples/p4me_1.zip')
    expect(content).not_to eql(nil)
    expect(content['boards'].length).to eql(3)
    board = content['boards'][0]
    expect(board['grid']['order']).to eql([
      ["0:_i1_" , "0:_i2_" , "0:_i5_" , "0:_i6_" ], 
      ["0:_i7_" , "0:_i8_" , nil      , "0:_i9_" ], 
      [nil      , "0:_i10_", nil      , nil      ]
    ])
    expect(board['name']).to eql("Happiness is good")
    button = board['buttons'][7]
    expect(button['id']).to eql("0:_i10_")
    expect(button['load_board']['id']).to eql("2")
    expect(button['image_id']).to eql("img:0:_i10_")
    expect(button['sound_id']).to eql(nil)
    expect(button['label']).to eql('more')
    expect(button['vocalization']).to eql('more')
    expect(button['border_color']).to eql(nil)
    expect(button['background_color']).to eql(nil)
    
    button = board['buttons'][1]
    expect(button['id']).to eql("0:_i2_")
    expect(button['image_id']).to eql("img:0:_i2_")
    expect(button['sound_id']).to eql(nil)
    expect(button['label']).to eql('sad')
    expect(button['vocalization']).to eql('sad')
    expect(button['border_color']).to eql(nil)
    expect(button['background_color']).to eql('#f90')

    expect(content['images'].length).to eql(12)
    
    image = content['images'][0]
    expect(image['content_type']).to eql('image/png')
    expect(image['width']).to eql(500)
    expect(image['height']).to eql(500)
    expect(image['id']).to eql('img:0:_i1_')
    expect(image['data']).to match(/data:image\/png;base64,iVBORw0KGgoAAAANS/)
    
    expect(content['sounds'].length).to eql(5)
    sound = content['sounds'][0]
    expect(sound['content_type']).to eql('audio/mpeg')
    expect(sound['id']).to eql('snd:0:_i6_')
    expect(sound['data']).to match(/data:audio\/mpeg;base64,\/\/NgxAAAAANIAUAAAP9oCt5p/)
  end
end
