class VimPerformanceState < ActiveRecord::Base
  serialize :state_data

  belongs_to :resource, :polymorphic => true

  ASSOCIATIONS = [:vms, :hosts, :ems_clusters, :ext_management_systems, :storages]

  # Define accessors for state_data information
  [
    :assoc_ids,
    :host_sockets,
    :parent_host_id,
    :parent_storage_id,
    :parent_ems_id,
    :parent_ems_cluster_id,
    :tag_names,
    :numvcpus,
    :total_cpu,
    :total_mem,
    :reserve_cpu,
    :reserve_mem,
    :vm_allocated_disk_storage,
    :vm_used_disk_storage
  ].each do |m|
    define_method(m)       { state_data[m] }
    define_method("#{m}=") { |value| state_data[m] = value }
  end

  # state_data:
  # => assoc_ids
  # => total_memory
  # => total_cpu
  # => reserve_memory
  # => reserve_cpu
  # => vm_count_on      (derive from assoc_ids)
  # => vm_count_off     (derive from assoc_ids)
  # => vm_count_total   (derive from assoc_ids)
  # => host_count_on    (derive from assoc_ids)
  # => host_count_off   (derive from assoc_ids)
  # => host_count_total (derive from assoc_ids)
  # => host_sockets     (derive from assoc_ids)

  def self.capture(obj)
    ts = Time.now.utc
    ts = Time.utc(ts.year, ts.month, ts.day, ts.hour)
    state = obj.vim_performance_states.find_by_timestamp(ts)
    return state unless state.nil?

    state = obj.vim_performance_states.build
    state.state_data ||= {}
    state.timestamp = ts
    state.capture_interval = 3600
    state.assoc_ids = capture_assoc_ids(obj)
    state.parent_host_id = capture_parent_host(obj)
    state.parent_storage_id = capture_parent_storage(obj)
    state.parent_ems_id = capture_parent_ems(obj)
    state.parent_ems_cluster_id = capture_parent_cluster(obj)
    # TODO: This is cpu_total_cores and needs to be renamed, but reports depend on the name :numvcpus
    state.numvcpus = capture_cpu_total_cores(obj)
    state.total_cpu = capture_total(obj, :cpu_speed)
    state.total_mem = capture_total(obj, :memory)
    state.reserve_cpu = capture_reserve(obj, :cpu_reserve)
    state.reserve_mem = capture_reserve(obj, :memory_reserve)
    state.vm_used_disk_storage = capture_vm_disk_storage(obj, :used_disk)
    state.vm_allocated_disk_storage = capture_vm_disk_storage(obj, :allocated_disk)
    state.tag_names = capture_tag_names(obj)
    state.host_sockets = capture_host_sockets(obj)
    state.save

    state
  end

  def vm_count_on
    get_assoc(:vms, :on).length
  end

  def vm_count_off
    get_assoc(:vms, :off).length
  end

  def vm_count_total
    get_assoc(:vms).length
  end

  def host_count_on
    get_assoc(:hosts, :on).length
  end

  def host_count_off
    get_assoc(:hosts, :off).length
  end

  def host_count_total
    get_assoc(:hosts).length
  end

  def storages
    ids = get_assoc(:storages, :on)
    ids.empty? ? [] : Storage.where(:id => ids).order(:id).to_a
  end

  def ext_management_systems
    ids = get_assoc(:ext_management_systems, :on)
    ids.empty? ? [] : ExtManagementSystem.where(:id => ids).order(:id).to_a
  end

  def ems_clusters
    ids = get_assoc(:ems_clusters, :on)
    ids.empty? ? [] : EmsCluster.where(:id => ids).order(:id).to_a
  end

  def hosts
    ids = get_assoc(:hosts)
    ids.empty? ? [] : Host.where(:id => ids).order(:id).to_a
  end

  def vms
    ids = get_assoc(:vms)
    ids.empty? ? [] : VmOrTemplate.where(:id => ids).order(:id).to_a
  end

  def get_assoc(relat, mode = nil)
    assoc = state_data.fetch_path(:assoc_ids, relat.to_sym)
    return [] if assoc.nil?

    ids = mode.nil? ? (assoc[:on] || []) + (assoc[:off] || []) : assoc[mode.to_sym]
    ids.nil? ? [] : ids.uniq.sort
  end

  def self.capture_total(obj, field)
    return obj.send("aggregate_#{field}") if obj.respond_to?("aggregate_#{field}")
    return nil unless obj.respond_to?(:hardware) && obj.hardware
    field == :memory ? obj.hardware.memory_mb : obj.hardware.aggregate_cpu_speed
  end

  def self.capture_assoc_ids(obj)
    result = {}
    ASSOCIATIONS.each do |assoc|
      method = assoc
      method = (obj.kind_of?(EmsCluster) ? :all_vms_and_templates : :vms_and_templates) if assoc == :vms
      next unless obj.respond_to?(method)
      assoc_recs = obj.send(method)
      has_state = assoc_recs[0] && assoc_recs[0].respond_to?(:state)

      r = result[assoc] = {:on => [], :off => []}
      r_on = r[:on]
      r_off = r[:off]
      assoc_recs.each do |o|
        state = has_state ? o.state : 'on'
        case state
        when 'on' then r_on << o.id
        else r_off << o.id
        end
      end

      r_on.uniq!
      r_on.sort!
      r_off.uniq!
      r_off.sort!
    end
    result.blank? ? nil : result
  end

  def self.capture_parent_cluster(obj)
    return unless obj.kind_of?(Host) || obj.kind_of?(VmOrTemplate)
    c = obj.parent_cluster
    c ? c.id : nil
  end

  def self.capture_parent_host(obj)
    return unless obj.kind_of?(VmOrTemplate)
    obj.host_id
  end

  def self.capture_parent_storage(obj)
    return unless obj.kind_of?(VmOrTemplate)
    obj.storage_id
  end

  def self.capture_parent_ems(obj)
    return unless obj.respond_to?(:ems_id)
    obj.ems_id
  end

  def self.capture_reserve(obj, field)
    return unless obj.respond_to?(field)
    obj.send(field)
  end

  def self.capture_tag_names(obj)
    obj.tag_list(:ns => "/managed").split.join("|")
  end

  def self.capture_vm_disk_storage(obj, field)
    return unless obj.kind_of?(VmOrTemplate)
    obj.send("#{field}_storage")
  end

  def self.capture_cpu_total_cores(obj)
    return unless obj.kind_of?(VmOrTemplate)
    obj.hardware.try(:cpu_total_cores)
  end

  def self.capture_host_sockets(obj)
    if obj.kind_of?(Host)
      obj.hardware.try(:cpu_sockets)
    else
      if obj.respond_to?(:hosts)
        obj.hosts.includes(:hardware).each_with_object([]) { |h, arr| arr << h.hardware.try(:cpu_sockets) }.compact.sum
      end
    end
  end
end
