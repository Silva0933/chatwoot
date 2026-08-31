json.payload do
  json.array! @tasks do |task|
    json.partial! 'api/v1/models/kanban_task', formats: [:json], resource: task
  end
end
