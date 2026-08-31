json.partial! 'api/v1/models/kanban_task', formats: [:json], resource: @task
json.stage_name @task.stage.name
json.pipeline_name @task.pipeline.name
