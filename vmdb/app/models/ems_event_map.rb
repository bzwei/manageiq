require "active_hash"

class EmsEventMap < ActiveYaml::Base
  fields :id, :ems_event_type, :miq_event_id, :system

  set_root_path "db/fixtures"
  set_filename "ems_event_maps"

  include ActiveHash::Associations
  belongs_to :miq_event

  def self.map_miq_event_id(raw_event_type)
    self.find_by_ems_event_type(raw_event_type).try(:miq_event_id)
  end

end
