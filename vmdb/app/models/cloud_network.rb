class CloudNetwork < ActiveRecord::Base
  belongs_to :ext_management_system, :foreign_key => :ems_id
  belongs_to :cloud_tenant
  belongs_to :cloud_stack
  has_many   :cloud_subnets, :dependent => :destroy
  has_many   :security_groups
  has_many   :vms
end
