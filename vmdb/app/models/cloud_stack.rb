class CloudStack < ActiveRecord::Base
  belongs_to :ext_management_system, :foreign_key => :ems_id
  belongs_to :cloud_template

  has_many   :vms, :class_name => "VmCloud"
  has_many   :security_groups
  has_many   :cloud_networks
  has_many   :cloud_stack_parameters, :dependent => :destroy
  has_many   :cloud_stack_outputs, :dependent => :destroy
  has_many   :cloud_stack_resources, :dependent => :destroy

  include RelationshipMixin
  self.default_relationship_type = "nested_stack"

  # @param options [Hash] what to update for the stack. Option keys and values are:
  #   :template (String, URI, S3::S3Object, Object) - A new stack template.
  #     This may be provided in a number of formats including:
  #       a String, containing the template in CFN or HOT format.
  #       a URL String pointing to the document in S3.
  #       a URI object pointing to the document in S3.
  #       an S3::S3Object which contains the template.
  #       an Object which responds to #to_json and returns the template.
  #   :parameters (Hash) - A hash that specifies the input parameters of the new stack.
  def update_stack_in_cloud(options)
    ext_management_system.cloud_formation.stacks[name].update(options) if ext_management_system.is_a? EmsAmazon
  end

  def delete_stack_in_cloud
    ext_management_system.cloud_formation.stacks[name].delete if ext_management_system.is_a? EmsAmazon
  end
end
