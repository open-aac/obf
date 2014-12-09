require 'spec_helper'

describe OBF::Sfy do
  it "should process a file" do
    board = OBF::Sgrid.to_external('./spec/samples/grid.xml')
    expect(board['name']).to eq('board')
    expect(board['id']).to eq('sgrid')
    expect(board['grid']).to eq({
      'rows' => 3,
      'columns' => 3,
      'order' => [
        [0,1,2],
        [3,4,5],
        [6,7,8]
      ]
    })
    expect(board['ext_sgrid_commands']).to eq(['action.speakall', 'action.clear'])
    expect(board['sounds'].length).to eq(0)
    expect(board['images'].length).to eq(7)
    expect(board['images'][0]).to eq({
      'id' => 0,
      'symbol' => {
        'set' => 'Grid2x',
        'filename' => 'jump.home.wmf'
      }
    })
    expect(board['images'][-1]).to eq({
      'id' => 6,
      'symbol' => {
        'set' => 'WIDGIT',
        'filename' => "widgit rebus\\c\\chocolate.emf"
      }
    })
    expect(board['buttons'].length).to eq(9)
    expect(board['buttons'][0]['id']).to eq(0)
    expect(board['buttons'][0]['label']).to eq(nil)
    expect(board['buttons'][0]['background_color']).to eq('rgb(255, 255, 255)')
    expect(board['buttons'][0]['border_color']).to eq('rgb(150, 150, 150)')

    expect(board['buttons'][1]['id']).to eq(1)
    expect(board['buttons'][1]['label']).to eq(nil)
    expect(board['buttons'][1]['background_color']).to eq('rgb(255, 255, 255)')
    expect(board['buttons'][1]['border_color']).to eq('rgb(150, 150, 150)')

    expect(board['buttons'][2]['id']).to eq(2)
    expect(board['buttons'][2]['label']).to eq('Jump home')
    expect(board['buttons'][2]['action']).to eq(':ext_sgrid_jump.home')
    expect(board['buttons'][2]['background_color']).to eq('rgb(200, 225, 255)')
    expect(board['buttons'][2]['border_color']).to eq('rgb(95, 135, 185)')

    expect(board['buttons'][3]['id']).to eq(3)
    expect(board['buttons'][3]['label']).to eq('Speak')
    expect(board['buttons'][3]['action']).to eq(':ext_sgrid_action.speakall')
    expect(board['buttons'][3]['background_color']).to eq('rgb(255, 200, 200)')
    expect(board['buttons'][3]['border_color']).to eq('rgb(155, 75, 75)')

    expect(board['buttons'][4]['id']).to eq(4)
    expect(board['buttons'][4]['label']).to eq('Clear')
    expect(board['buttons'][4]['action']).to eq(':clear')
    expect(board['buttons'][4]['background_color']).to eq('rgb(255, 200, 200)')
    expect(board['buttons'][4]['border_color']).to eq('rgb(155, 75, 75)')

    expect(board['buttons'][5]['id']).to eq(5)
    expect(board['buttons'][5]['label']).to eq('Jump back')
    expect(board['buttons'][5]['action']).to eq(':ext_sgrid_jump.back')
    expect(board['buttons'][5]['background_color']).to eq('rgb(200, 225, 255)')
    expect(board['buttons'][5]['border_color']).to eq('rgb(95, 135, 185)')

    expect(board['buttons'][6]['id']).to eq(6)
    expect(board['buttons'][6]['label']).to eq('How are you?')
    expect(board['buttons'][6]['vocalization']).to eq('How are you? ')
    expect(board['buttons'][6]['background_color']).to eq('rgb(255, 255, 155)')
    expect(board['buttons'][6]['border_color']).to eq('rgb(150, 135, 32)')

    expect(board['buttons'][7]['id']).to eq(7)
    expect(board['buttons'][7]['label']).to eq('Hello')
    expect(board['buttons'][7]['vocalization']).to eq('Hello ')
    expect(board['buttons'][7]['background_color']).to eq('rgb(255, 255, 155)')
    expect(board['buttons'][7]['border_color']).to eq('rgb(150, 135, 32)')

    expect(board['buttons'][8]['id']).to eq(8)
    expect(board['buttons'][8]['label']).to eq('I like chocolate')
    expect(board['buttons'][8]['vocalization']).to eq('I like chocolate ')
    expect(board['buttons'][8]['background_color']).to eq('rgb(255, 255, 155)')
    expect(board['buttons'][8]['border_color']).to eq('rgb(150, 135, 32)')
    expect(board['buttons'][8]['ext_sgrid_commands']).to eq([{
      'type' => 'type',
      'parameters' => ['I like chocolate ']
    }])
  end
end
