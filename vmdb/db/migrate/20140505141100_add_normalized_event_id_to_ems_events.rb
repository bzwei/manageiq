class AddNormalizedEventIdToEmsEvents < ActiveRecord::Migration
  def change
    add_column :ems_events, :miq_event_id, :bigint
  end
end
