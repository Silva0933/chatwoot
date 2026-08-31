json.payload do
  json.array! @members do |member|
    json.partial! 'api/v1/models/kanban_pipeline_member', formats: [:json], resource: member
  end
end
