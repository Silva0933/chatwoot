json.id resource.id
json.account_id resource.account_id
json.name resource.name
json.description resource.description
json.is_active resource.is_active
json.position resource.position
json.stages do
  json.array! resource.stages do |stage|
    json.partial! 'api/v1/models/kanban_stage', formats: [:json], resource: stage
  end
end
if resource.automation.present?
  json.automation do
    json.partial! 'api/v1/models/kanban_automation', formats: [:json], resource: resource.automation
  end
else
  json.automation nil
end
