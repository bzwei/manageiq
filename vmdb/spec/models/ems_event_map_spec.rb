require "spec_helper"

describe EmsEventMap do
  before(:each) do
    @map = EmsEventMap.new(id: 1, ems_event_type: 'test', miq_event_id: 100, system: true)
    EmsEventMap.should_receive(:find_by_ems_event_type).with(@map.ems_event_type).and_return(@map)
  end

  it ".map_miq_event_id" do
    miq_event_id = EmsEventMap.map_miq_event_id(@map.ems_event_type)
    miq_event_id.should eq @map.miq_event_id
  end
end
