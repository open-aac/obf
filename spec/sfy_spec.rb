require 'spec_helper'

describe OBF::Sfy do
  it "should process a linked set" do
    content = OBF::Sfy.to_external('./spec/samples/sfy.data')
    expect(content).not_to eql(nil)
    expect(content['sounds']).to eq([])
    expect(content['images'].length).to eq(317)
    expect(content['images'][0]).to eq({'id' => 0, 'symbol' => {'set' => 'sfy', 'name' => 'eye_02'}})
    expect(content['images'][100]).to eq({'id' => 100, 'symbol' => {'set' => 'sfy', 'name' => 'shake hands'}})
    expect(content['boards'].length).to eq(6)
    expect(content['boards'][0]['name']).to eq("HOME")
    expect(content['boards'][0]['id']).to eq("0")
    expect(content['boards'][0]['buttons'].length).to eq(119)
    expect(content['boards'][1]['name']).to eq("I")
    expect(content['boards'][1]['id']).to eq("1")
    expect(content['boards'][1]['buttons'].length).to eq(1)
    expect(content['boards'][2]['name']).to eq("YOU")
    expect(content['boards'][2]['id']).to eq("16")
    expect(content['boards'][2]['buttons'].length).to eq(1)
    expect(content['boards'][3]['name']).to eq("EAT")
    expect(content['boards'][3]['id']).to eq("68")
    expect(content['boards'][3]['buttons'].length).to eq(108)
    expect(content['boards'][4]['name']).to eq("WANT")
    expect(content['boards'][4]['id']).to eq("92")
    expect(content['boards'][4]['buttons'].length).to eq(23)
    expect(content['boards'][5]['name']).to eq("DRINK")
    expect(content['boards'][5]['id']).to eq("113")
    expect(content['boards'][5]['buttons'].length).to eq(66)
    
    buttons = content['boards'][0]['buttons']
    expect(buttons[0]).to eql({
       "background_color" => "rgb(252, 242, 134)",
       "ext_sfy_backgroundColorID" => 8,
       "ext_sfy_isLinked" => false,
       "hidden" => false,
       "ext_sfy_isProtected" => true,
       "id" => 0,
       "image_id" => 0,
       "label" => "I",
    })
    expect(buttons[1]).to eql({
       "background_color" => "rgb(252, 242, 134)",
       "ext_sfy_backgroundColorID" => 8,
       "ext_sfy_isLinked" => false,
       "hidden" => true,
       "ext_sfy_isProtected" => true,
       "id" => 1,
       "image_id" => 1,
       "label" => "MY",
    })
    expect(buttons[67]).to eql({
       "background_color" => "rgb(255, 255, 255)",
       "ext_sfy_backgroundColorID" => 0,
       "ext_sfy_isLinked" => true,
       "hidden" => false,
       "ext_sfy_isProtected" => true,
       "id" => 67,
       "image_id" => 67,
       "label" => "EAT",
       "load_board" => {"id"=>"68"},
    })
    expect(buttons[91]).to eql({
       "background_color" => "rgb(255, 255, 255)",
       "ext_sfy_backgroundColorID" => 0,
       "ext_sfy_isLinked" => true,
       "hidden" => false,
       "ext_sfy_isProtected" => true,
       "id" => 91,
       "image_id" => 91,
       "label" => "WANT",
       "load_board" => {"id"=>"92"},
    })
    expect(buttons[112]).to eql({
       "background_color" => "rgb(255, 255, 255)",
       "ext_sfy_backgroundColorID" => 0,
       "ext_sfy_isLinked" => true,
       "hidden" => false,
       "ext_sfy_isProtected" => true,
       "id" => 112,
       "image_id" => 112,
       "label" => "DRINK",
       "load_board" => {"id"=>"113"},
    })
  end
end
