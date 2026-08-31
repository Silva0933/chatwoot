json.id resource.id
json.pipeline_id resource.kanban_pipeline_id
json.user_id resource.user_id
json.role resource.role
json.user do
  json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.user
end
