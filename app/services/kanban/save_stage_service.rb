class Kanban::SaveStageService
  pattr_initialize [:pipeline!, :params!, :stage]

  def perform
    ActiveRecord::Base.transaction do
      record = stage || build_stage
      record.assign_attributes(attributes)
      release_terminal_flags(record)
      record.save!
      record
    end
  end

  private

  def build_stage
    pipeline.stages.new(account_id: pipeline.account_id, position: next_position)
  end

  def next_position
    (pipeline.stages.maximum(:position) || -1) + 1
  end

  def attributes
    params.slice(:name, :color_hex, :is_won_stage, :is_lost_stage, :position).to_h.symbolize_keys
  end

  # Postgres enforces "one won stage and one lost stage per pipeline" with partial
  # unique indexes, so promoting a second stage would just raise. Demote the
  # incumbent first, inside the same transaction, and the move reads as a swap
  # instead of an error the admin has to decipher.
  def release_terminal_flags(record)
    %i[is_won_stage is_lost_stage].each do |flag|
      next unless record.public_send(flag)

      pipeline.stages.where(flag => true).where.not(id: record.id).update_all(flag => false, updated_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
