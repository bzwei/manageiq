require 'digest/md5'
class CloudTemplate < ActiveRecord::Base
  has_many :cloud_stacks

  # Find only by template content. Here we only compare md5 considering the table is expected
  # to be small and the chance of md5 collision is minimal.
  #
  def self.find_or_create_by_template(hash, update = false)
    rescue_count ||= 0
    hash[:md5] ||= Digest::MD5.hexdigest(hash[:template])
    template = self.find_or_create_by_md5(hash)
    template.update_attributes(hash) if update
    template
  end

  # deploy the template to a cloud as a stack
  # @param options [Hash] can contain the following keys and values:
  #   :capabilities (Array<String>) - The list of capabilities that you want to allow in the stack.
  #        If your stack contains IAM resources, you must specify the CAPABILITY_IAM value for this parameter;
  #        otherwise, this action returns an InsufficientCapabilities error. IAM resources are the following:
  #     AWS::IAM::AccessKey
  #     AWS::IAM::Group
  #     AWS::IAM::Policy
  #     AWS::IAM::User
  #     AWS::IAM::UserToGroupAddition
  #   :disable_rollback (Boolean) - default: false - Set to true to disable rollback on stack creation failures.
  #   :notify (Object)   - One or more SNS topics ARN string or SNS::Topic objects. This param may be passed as a
  #                        single value or as an array.
  #                        CloudFormation will publish stack related events to these topics.
  #   :parameters (Hash) - A hash that specifies the input parameters of the new stack.
  #   :timeout (Integer) - The number of minutes that may pass before the stack creation fails.
  #                        If :disable_rollback is false, the stack will be rolled back.
  def deploy(ems, stack_name, options = {}, tenant_name = nil)
    if ems.is_a? EmsAmazon
      ems.cloud_formation.stacks.create(stack_name, template, options)
    elsif ems.is_a? EmsOpenstack
      options = {:template => template}.merge(options)
      ems.openstack_handle.orchestration_service(tenant_name).create_stack(stack_name, options)
    end
  end
end
