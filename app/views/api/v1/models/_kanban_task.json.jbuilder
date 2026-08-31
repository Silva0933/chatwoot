json.id resource.id
json.pipeline_id resource.kanban_pipeline_id
json.stage_id resource.kanban_stage_id
json.conversation_id resource.conversation_id
json.contact_id resource.contact_id
json.inbox_id resource.inbox_id
json.title resource.title
json.priority resource.priority
json.due_date resource.due_date
json.stage_entered_at resource.stage_entered_at
json.position resource.position
json.metadata resource.metadata

json.contact do
  json.partial! 'api/v1/models/contact', formats: [:json], resource: resource.contact
end

if resource.assigned_agent.present?
  json.assigned_agent do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.assigned_agent
  end
else
  json.assigned_agent nil
end

json.channel_type resource.inbox&.channel_type || resource.conversation&.inbox&.channel_type
