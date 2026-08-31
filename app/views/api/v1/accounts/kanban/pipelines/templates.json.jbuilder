json.payload do
  json.array! @templates do |key, template|
    json.key key
    json.name template[:name]
    json.description template[:description]
    json.stages do
      json.array! template[:stages] do |stage|
        json.name stage[:name]
        json.color_hex stage[:color_hex]
        json.is_won_stage stage[:is_won_stage].present?
        json.is_lost_stage stage[:is_lost_stage].present?
      end
    end
  end
end
