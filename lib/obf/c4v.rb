module OBF::C4v
  def self.to_external(c4v_path)
    # load the sqlite file, read the following into memory:
    # - action_data
    # - actions
    # - button_box_cells
    # - button_box_instances
    # - button_boxes
    # - button_set_modifiers
    # - button_sets
    # - button_styles
    # - buttons
    # - pages
    # - resources
    # - special_pages

    # then use the munger code to convert to a hash of boards
  end
end


# # buttons => id, label, message, resource_id, button_style_id
# # button_box_cells => button_box_id, resource_id (buttons), location
# # button_box_instances => page_id (pages), button_box_id
# # button_boxes => id, layout_x (cols), layout_y (rows)
# # button_styles => id, body_color, etc.
# # pages => id, resource_id, button_style_id (?)
# # actions => id, resource_id, code
# # action_data => action_id, value
# # resource => id, rid, name, type

# # buttons.resource_id == button_box_cells.resource_id (where buttons go in the layout)
# # buttons.resource_id == actions.resource_id (action for each button, code=8 is a link, code=13 is maybe an append?)
# # action_data.action_id == actions.id
# # action_data.value == resources.rid (where each button links to)
# # resources.id == pages.resource_id (page name for reference)

# # resources
# # type 7 == board
# # type 4 == button
# # type 5 == special button

# require 'json'
# require 'fileutils'
# require 'zip'
# require 'csv'

# Dir.glob('*')
# ["LAMP 84 Full"]
# Dir.glob('*').each do |dir|
#   puts dir
#   if dir
#     refs = {}
#     Dir.glob("./#{dir}/*.json").each do |json|
#       puts "  #{json}"
#       type = json.split(/\//)[-1].split(/\./)[0]
#       refs[type] = JSON.parse(File.read(json))
#     end
#     if refs.keys.length > 0
#       root_path = "./#{dir}/output"
#       FileUtils.mkdir_p root_path

#       home_page_id = refs['special_pages'].detect{|p| p['name'] == 'HOME'}['page_id']
#       manifest = {
#         'format' => 'open-board-0.1',
#         'root' => "boards/#{home_page_id}.obf",
#         'paths' => {
#           'boards' => {
#           }
#         }
#       }
      
#       home_page = refs['pages'].detect{|p| p['id'] == home_page_id }
#       processed_pages = []
#       pages_to_process = [home_page]
#       bbis = {}
#       refs['button_box_instances'].each{|bbi| bbis[bbi['page_id']] = bbi}
#       rs = {}
#       refs['resources'].each{|r| rs[r['id']] = r; rs[r['rid']] = r }
#       btns = {}
#       words = []
#       refs['buttons'].each{|b| btns[b['resource_id']] = b; words << b['message'] }
#       words = words.select{|w| w && w.length > 0 && w != ' '}.sort.uniq
#       CSV.open(root_path + "/#{dir} words.csv", 'wb') do |csv|
#         words.each{|w| csv << [w] }
#       end
#       File.write(root_path + "/#{dir} words.txt", words.join("\n"))
#       acts = {}
#       refs['actions'].each{|a| acts[a['resource_id']] ||= []; acts[a['resource_id']] << a }
#       pgs = {}
#       refs['pages'].each{|p| pgs[p['resource_id']] = p }
#       ads = {}
#       refs['action_data'].each{|d| ads[d['action_id']] ||= []; ads[d['action_id']] << d }
#       cls = {}
#       refs['button_box_cells'].each{|c| cls[c['button_box_id']] ||= []; cls[c['button_box_id']] << c }
#       bxs = {}
#       refs['button_boxes'].each{|b| bxs[b['id']] = b }
#       bsts = {}
#       refs['button_styles'].each{|b| bsts[b['id']] = b }
#       btnsts = {}
#       refs['button_sets'].each{|b| btnsts[b['resource_id']] = b }
#       btnmd = {}
#       refs['button_set_modifiers'].each{|b| btnmd[b['button_set_id']] = b if b['modifier'] == 0 }

#       while pages_to_process.length > 0
#         page = pages_to_process.shift
#         manifest['paths']['boards'][page['id']] = "boards/#{page['id']}.obf"
#         processed_pages.push(page['id'])
#         page_name = rs[page['resource_id']]['name']
#         page_name = dir if page['id'] == home_page_id
#         board = {
#           'format' => 'open-board-0.1',
#           'id' => page['id'],
#           'locale' => 'en',
#           'name' => page_name,
#           'description' => "Auto-Generated",
#           'buttons' => [],
#           'grid' => {
#             'rows' => 0,
#             'columns' => 0,
#             'order' => []
#           }
#         }
#         button_box_instance = bbis[page['id']] #refs['button_box_instances'].detect{|b| b['page_id'] == page['id'] }
#         button_box_id = button_box_instance['button_box_id']
#         puts "    #{page_name} #{button_box_id}"
#         button_box = bxs[button_box_id] #refs['button_boxes'].detect{|b| b['id'] == button_box_instance }
#         columns = button_box['layout_x']
#         rows = button_box['layout_y']
#         board['grid']['rows'] = rows
#         board['grid']['columns'] = columns
#         cells = cls[button_box_id] #refs['button_box_cells'].select{|c| c['button_box_id'] == button_box_id }
#         cells.each do |cell|
#           # TODO: add coloring from button_styles
#           col = cell['location'] % columns
#           row = (cell['location'] - col) / columns
#           resource_id = cell['resource_id']
#           resource = rs[cell['resource_id']]
#           if resource && resource['type'] == 5
#             button_set = btnsts[resource_id]
#             button_mod = button_set && btnmd[button_set['id']]
#             button_id = button_mod && button_mod['button_id']
#             button = refs['buttons'].detect{|b| b['id'] == button_id}
#             resource_id = button['resource_id'] if button
#           end
#           cell['button'] = btns[resource_id] #refs['buttons'].detect{|b| b['resource_id'] == cell['resource_id'] }
#           cell['style'] = cell['button'] && bsts[cell['button']['button_style_id']]
#           label = (cell['button'] && cell['button']['label']) || rs[cell['resource_id']]['name']
#           cell['actions'] = acts[cell['resource_id']] || []
#           cell['actions'] += acts[resource_id] || [] #refs['actions'].select{|b| b['resource_id'] == cell['resource_id'] }
#           link_id = nil
#           verbose = button_box_id == 268 && row == 0 && col == 3
#           cell['actions'].each do |action|
#             if action && (action['code'] == 8 || action['code'] == 9 || action['code'] == 73 || (button_box_id == 268 && row == 0 && col == 2))
#               action_data = ads[action['id']] #refs['action_data'].detect{|a| a['action_id'] == action['id'] }
#               action['data'] = action_data
#               (action_data || []).each do |ad|
#                 if ad && ad['value'] != '0' && ad['value'] != '1'
#                   action_resource = rs[ad['value']] #refs['resources'].detect{|r| r['rid'] == action_data['value'] }
#                   if !action_resource || action_resource['type'] != 7
#                     puts JSON.pretty_generate(cell)
#                     puts ad.to_json
#                     puts action_resource.to_json
#                     raise "wut"
#                   end
#                   puts ad['value'].to_json if !action_resource
#                   new_page = pgs[action_resource['id']] #refs['pages'].detect{|p| p['resource_id'] == action_resource['id'] }
#                   link_id = new_page['id']
#                   if !processed_pages.include?(new_page['id']) && !pages_to_process.detect{|p| p['id'] == new_page['id'] }
#                     pages_to_process.push(new_page)
#                   end
#                 end
#               end
#             end
#           end
#           puts JSON.pretty_generate(cell) if verbose
#           if label && label != ''
# #            puts "      #{label.to_json} #{row} #{col}"
#             button = {
#               'id' => cell['id'],
#               'label' => label
#             }
#             if cell['button'] && cell['button']['message']
#               button['vocalization'] = cell['button']['message']
#             end
#             if link_id
#               button['load_board'] = {
#                 'id' => link_id,
#                 'path' => "boards/#{link_id}.obf"
#               }
#             end
#             if cell['style']
#               button['background_color'] = "\##{cell['style']['body_color'].to_s(16).rjust(6, '0')}" if cell['style']['body_color']
#               button['border_color'] = "\##{cell['style']['border_color'].to_s(16).rjust(6, '0')}" if cell['style']['border_coloor']
#             end
#             board['buttons'] << button
#             board['grid']['order'][row] ||= []
#             board['grid']['order'][row][col] = button['id']
#           end
#         end
#         FileUtils.mkdir_p(root_path + "/boards")
#         File.write(root_path + "/boards/#{page['id']}.obf", JSON.pretty_generate(board))
#       end

#       File.write(root_path + "/manifest.json", JSON.pretty_generate(manifest))
#       File.unlink(root_path + "/#{dir}.obz") if File.exists?(root_path + "/#{dir}.obz")
#       Zip::File.open(root_path + "/#{dir}.obz", Zip::File::CREATE) do |zipfile|
#         zipfile.add("manifest.json", root_path + "/manifest.json")
#         manifest['paths']['boards'].each do |id, path|
#           zipfile.add(path, root_path + "/" + path)
#         end
#       end      
#     end
#   end
# end