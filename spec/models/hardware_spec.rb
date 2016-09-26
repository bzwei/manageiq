describe Hardware do
  include Spec::Support::ArelHelper
  let(:vm) { FactoryGirl.create(:vm_vmware, :hardware => FactoryGirl.create(:hardware)) }
  let(:template) { FactoryGirl.create(:template_vmware, :hardware => FactoryGirl.create(:hardware)) }
  let(:host) { FactoryGirl.create(:host, :hardware => FactoryGirl.create(:hardware)) }

  it "#vm_or_template" do
    expect(vm.hardware.vm_or_template).to eq(vm)
    expect(template.hardware.vm_or_template).to eq(template)
    expect(host.hardware.vm_or_template).to     be_nil
  end

  it "#vm" do
    expect(vm.hardware.vm).to eq(vm)
    expect(template.hardware.vm).to be_nil
    expect(host.hardware.vm).to     be_nil
  end

  it "#miq_template" do
    expect(vm.hardware.miq_template).to       be_nil
    expect(template.hardware.miq_template).to eq(template)
    expect(host.hardware.miq_template).to     be_nil
  end

  it "#host" do
    expect(vm.hardware.host).to       be_nil
    expect(template.hardware.host).to be_nil
    expect(host.hardware.host).to eq(host)
  end

  describe ".aggregate_cpu_speed" do
    context "with empty hardware" do
      let(:hardware) { FactoryGirl.build(:hardware) }
      it "bails ruby calculation" do
        expect(hardware.aggregate_cpu_speed).to be_nil
      end

      it "bails database calculation" do
        hardware.save
        expect(virtual_column_sql_value(Hardware, "aggregate_cpu_speed")).to be_nil
      end
    end

    context "with values" do
      let(:hardware) { FactoryGirl.build(:hardware, :cpu_total_cores => 4, :cpu_speed => 1000) }

      it "calculates in ruby" do
        expect(hardware.aggregate_cpu_speed).to eq(4000)
      end

      it "calculates in the database" do
        hardware.save
        expect(virtual_column_sql_value(Hardware, "aggregate_cpu_speed")).to eq(4000)
      end
    end
  end

  describe ".v_pct_free_disk_space" do
    context "with empty hardware" do
      let(:hardware) { FactoryGirl.build(:hardware) }
      it "bails ruby calculation" do
        expect(hardware.v_pct_free_disk_space).to be_nil
        expect(hardware.v_pct_used_disk_space).to be_nil
      end

      it "bails database calculation" do
        hardware.save
        expect(virtual_column_sql_value(Hardware, "v_pct_free_disk_space")).to be_nil
        expect(virtual_column_sql_value(Hardware, "v_pct_used_disk_space")).to be_nil
      end
    end

    context "with values" do
      let(:hardware) { FactoryGirl.build(:hardware, :disk_free_space => 20, :disk_capacity => 100) }

      it "calculates in ruby" do
        expect(hardware.v_pct_free_disk_space).to eq(20.0)
        expect(hardware.v_pct_used_disk_space).to eq(80.0)
      end

      it "calculates in the database" do
        hardware.save
        expect(virtual_column_sql_value(Hardware, "v_pct_free_disk_space")).to eq(20.0)
        expect(virtual_column_sql_value(Hardware, "v_pct_used_disk_space")).to eq(80.0)
      end
    end

    context "with 0 disk free " do
      let(:hardware) { FactoryGirl.build(:hardware, :disk_free_space => 0, :disk_capacity => 100) }

      it "calculates in ruby" do
        expect(hardware.v_pct_free_disk_space).to eq(0.0)
        expect(hardware.v_pct_used_disk_space).to eq(100.0)
      end

      it "calculates in the database" do
        hardware.save
        expect(virtual_column_sql_value(Hardware, "v_pct_free_disk_space")).to eq(0.0)
        expect(virtual_column_sql_value(Hardware, "v_pct_used_disk_space")).to eq(100.0)
      end
    end

    context "with null disk capacity" do
      let(:hardware) { FactoryGirl.build(:hardware, :disk_free_space => 20, :disk_capacity => nil) }

      it "calculates in ruby" do
        expect(hardware.v_pct_free_disk_space).to eq(nil)
        expect(hardware.v_pct_used_disk_space).to eq(nil)
      end

      it "calculates in the database" do
        hardware.save
        expect(virtual_column_sql_value(Hardware, "v_pct_free_disk_space")).to eq(nil)
        expect(virtual_column_sql_value(Hardware, "v_pct_used_disk_space")).to eq(nil)
      end
    end
  end

  describe ".allocated_disk_storage" do
    let(:hardware) { FactoryGirl.create(:hardware) }

    context "with no disks" do
      it "bails ruby calculation" do
        expect(hardware.allocated_disk_storage).to eq(0) # TODO
      end

      it "bails database calculation" do
        hardware
        expect(virtual_column_sql_value(Hardware, "allocated_disk_storage")).to be_nil
      end
    end

    context "with disks" do
      before do
        FactoryGirl.create(:disk, :size_on_disk => 1024, :size => 10240, :hardware => hardware)
        FactoryGirl.create(:disk, :size => 1024, :hardware => hardware)
        FactoryGirl.create(:disk, :hardware => hardware)
      end

      it "calculates in ruby" do
        expect(hardware.allocated_disk_storage).to eq(11264)
      end

      it "calculates in the database" do
        hardware
        expect(virtual_column_sql_value(Hardware, "allocated_disk_storage")).to eq(11264)
      end
    end
  end

  describe ".used_disk_storage" do
    let(:hardware) { FactoryGirl.create(:hardware) }

    context "with no disks" do
      it "bails ruby calculation" do
        expect(hardware.used_disk_storage).to eq(0) # TODO
      end

      it "bails database calculation" do
        hardware
        expect(virtual_column_sql_value(Hardware, "used_disk_storage")).to be_nil
      end
    end

    context "with disks" do
      before do
        FactoryGirl.create(:disk, :size_on_disk => 1024, :size => 10240, :hardware => hardware)
        FactoryGirl.create(:disk, :size => 1024, :hardware => hardware)
        FactoryGirl.create(:disk, :hardware => hardware)
      end

      it "calculates in ruby" do
        expect(hardware.used_disk_storage).to eq(2048)
      end

      it "calculates in the database" do
        hardware
        expect(virtual_column_sql_value(Hardware, "used_disk_storage")).to eq(2048)
      end
    end
  end
end
