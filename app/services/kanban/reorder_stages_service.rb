class Kanban::ReorderStagesService
  pattr_initialize [:pipeline!, :stage_ids!]

  def perform
    ordered = pipeline.stages.where(id: stage_ids).index_by(&:id)

    ActiveRecord::Base.transaction do
      stage_ids.map(&:to_i).each_with_index do |stage_id, index|
        stage = ordered[stage_id]
        next if stage.blank?

        stage.update!(position: index)
      end
    end

    pipeline.reload
  end
end
