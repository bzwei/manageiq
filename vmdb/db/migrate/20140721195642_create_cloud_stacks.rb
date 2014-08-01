class CreateCloudStacks < ActiveRecord::Migration
  def change
    create_table :cloud_templates do |t|
      t.string   :name
      t.text     :description
      t.string   :format
      t.boolean  :user_provided, :default => true
      t.text     :template
      t.string   :md5

      t.timestamps
    end

    add_index :cloud_templates, :md5, :unique => true

    create_table :cloud_stacks do |t|
      t.string  :name
      t.string  :vendor
      t.text    :description
      t.string  :status
      t.string  :ems_ref

      t.belongs_to :ems
      t.belongs_to :cloud_template

      t.timestamps
    end

    add_index :cloud_stacks, :cloud_template_id

    add_column :vms, :cloud_stack_id, :bigint
    add_column :security_groups, :cloud_stack_id, :bigint
    add_column :cloud_networks, :cloud_stack_id, :bigint

    create_table :cloud_stack_parameters do |t|
      t.string :name
      t.string :value

      t.belongs_to :cloud_stack
    end

    add_index :cloud_stack_parameters, :cloud_stack_id

    create_table :cloud_stack_outputs do |t|
      t.string :key
      t.text   :value
      t.text   :description

      t.belongs_to :cloud_stack
    end

    add_index :cloud_stack_outputs, :cloud_stack_id

    create_table :cloud_stack_resources do |t|
      t.string :name
      t.text   :description
      t.string :logical_resource_id
      t.text   :physical_resource_id
      t.string :resource_type
      t.string :resource_status
      t.text   :resource_status_reason
      t.timestamp :last_updated_timestamp

      t.belongs_to :cloud_stack
    end

    add_index :cloud_stack_resources, :cloud_stack_id
  end
end
