require "spec_helper"

describe AsyncDeleteMixin do
  def common_setup(klass)
    objects = []
    3.times do |i|
      obj = FactoryGirl.create(klass, :name => "test_#{klass}_#{i}")
      objects << obj
    end

    return objects, objects.first
  end

  def self.should_define_destroy_queue_instance_method
    it "should define destroy_queue instance method" do
      @obj.respond_to?(:destroy_queue).should be_true, "instance method destroy_queue not defined for #{@obj.class.name}"
    end
  end

  def self.should_define_destroy_queue_class_method
    it "should define destroy_queue class method" do
      @obj.class.respond_to?(:destroy_queue).should be_true, "class method destroy_queue not defined for #{@obj.class.name}"
    end
  end

  def self.should_define_delete_queue_instance_method
    it "should define delete_queue instance method" do
      @obj.respond_to?(:delete_queue).should be_true, "instance method delete_queue not defined for #{@obj.class.name}"
    end
  end

  def self.should_define_delete_queue_class_method
    it "should define delete_queue class method" do
      @obj.class.respond_to?(:delete_queue).should be_true, "class method delete_queue not defined for #{@obj.class.name}"
    end
  end

  def self.should_queue_destroy_on_instance
    it "should queue up destroy on instance" do
      cond = ["class_name = ? AND instance_id = ? AND method_name = ?", @obj.class.name, @obj.id, "destroy"]

      -> { @obj.destroy_queue }.should_not raise_error
      MiqQueue.where(cond).count.should == 1
      @obj.class.any_instance.should_receive(:destroy).once

      queue_message = MiqQueue.where(cond).first
      status, message, result = queue_message.deliver
      queue_message.delivered(status, message, result)
      queue_message.state.should == "ok"
    end
  end

  def self.should_queue_destroy_on_class_with_many_ids
    it "should queue up destroy on class method with many ids" do
      ids = @objects.collect(&:id)
      cond = ["class_name = ? AND instance_id in (?) AND method_name = ?", @obj.class.name, ids, "destroy"]

      -> { @obj.class.destroy_queue(ids) }.should_not raise_error
      MiqQueue.where(cond).count.should == ids.length
      count = @obj.class.count

      queue_messages = MiqQueue.where(cond)
      queue_messages.each do |queue_message|
        status, message, result = queue_message.deliver
        queue_message.delivered(status, message, result)
        queue_message.state.should == "ok"
      end
      @obj.class.count.should == (count - ids.length)
    end
  end

  def self.should_queue_delete_on_instance
    it "should queue up delete on instance" do
      cond = ["class_name = ? AND instance_id = ? AND method_name = ?", @obj.class.name, @obj.id, "delete"]

      -> { @obj.delete_queue }.should_not raise_error
      MiqQueue.where(cond).count.should == 1
      @obj.class.any_instance.should_receive(:delete).once

      queue_message = MiqQueue.where(cond).first
      status, message, result = queue_message.deliver
      queue_message.delivered(status, message, result)
      queue_message.state.should == "ok"
    end
  end

  def self.should_queue_delete_on_class_with_many_ids
    it "should queue up delete on class method with many ids" do
      ids = @objects.collect(&:id)
      cond = ["class_name = ? AND instance_id in (?) AND method_name = ?", @obj.class.name, ids, "delete"]

      -> { @obj.class.delete_queue(ids) }.should_not raise_error
      MiqQueue.where(cond).count.should == ids.length
      count = @obj.class.count

      queue_messages = MiqQueue.where(cond)
      queue_messages.each do |queue_message|
        status, message, result = queue_message.deliver
        queue_message.delivered(status, message, result)
        queue_message.state.should == "ok"
      end
      @obj.class.count.should == (count - ids.length)
    end
  end

  context "with zone and server" do
    before(:each) do
      EvmSpecHelper.local_miq_server
    end

    context "with 3 ems clusters" do
      before(:each) do
        @objects, @obj = common_setup(:ems_cluster)
      end

      should_define_destroy_queue_instance_method
      should_define_destroy_queue_class_method
      should_queue_destroy_on_instance
      should_queue_destroy_on_class_with_many_ids

      should_define_delete_queue_instance_method
      should_define_delete_queue_class_method
      should_queue_delete_on_instance
      should_queue_delete_on_class_with_many_ids
    end

    context "with 3 ems" do
      before(:each) do
        @objects, @obj = common_setup(:ems_vmware)
      end

      should_define_destroy_queue_instance_method
      should_define_destroy_queue_class_method
      should_queue_destroy_on_instance
      should_queue_destroy_on_class_with_many_ids

      should_define_delete_queue_instance_method
      should_define_delete_queue_class_method
      should_queue_delete_on_instance
      should_queue_delete_on_class_with_many_ids
    end

    context "with 3 hosts" do
      before(:each) do
        @objects, @obj = common_setup(:host)
      end

      should_define_destroy_queue_instance_method
      should_define_destroy_queue_class_method
      should_queue_destroy_on_instance
      should_queue_destroy_on_class_with_many_ids

      should_define_delete_queue_instance_method
      should_define_delete_queue_class_method
      should_queue_delete_on_instance
      should_queue_delete_on_class_with_many_ids
    end

    context "with 3 repositories" do
      before(:each) do
        @objects, @obj = common_setup(:repository)
      end

      should_define_destroy_queue_instance_method
      should_define_destroy_queue_class_method
      should_queue_destroy_on_instance
      should_queue_destroy_on_class_with_many_ids

      should_define_delete_queue_instance_method
      should_define_delete_queue_class_method
      should_queue_delete_on_instance
      should_queue_delete_on_class_with_many_ids
    end

    context "with 3 resource pools" do
      before(:each) do
        @objects, @obj = common_setup(:resource_pool)
      end

      should_define_destroy_queue_instance_method
      should_define_destroy_queue_class_method
      should_queue_destroy_on_instance
      should_queue_destroy_on_class_with_many_ids

      should_define_delete_queue_instance_method
      should_define_delete_queue_class_method
      should_queue_delete_on_instance
      should_queue_delete_on_class_with_many_ids
    end

    context "with 3 storages" do
      before(:each) do
        @objects, @obj = common_setup(:storage)
      end

      should_define_destroy_queue_instance_method
      should_define_destroy_queue_class_method
      should_queue_destroy_on_instance
      should_queue_destroy_on_class_with_many_ids

      should_define_delete_queue_instance_method
      should_define_delete_queue_class_method
      should_queue_delete_on_instance
      should_queue_delete_on_class_with_many_ids
    end
  end
end
