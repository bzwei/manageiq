require "spec_helper"
require "digest/md5"

describe CloudTemplate do
  DB_HASH = {
    :name        => "name",
    :template    => "any template text",
    :md5         => Digest::MD5.hexdigest("any template text"),
    :description => "some description"
  }

  describe ".find_or_create_by_template" do
    context "when the template does not exist" do
      before do
        @query_hash = DB_HASH.clone
      end

      it "creates a new template" do
        record = CloudTemplate.find_or_create_by_template(@query_hash)
        record.name.should eq @query_hash[:name]
        record.template.should eq @query_hash[:template]
      end
    end

    context "when the template already exists" do
      before do
        @existing_record = CloudTemplate.create(DB_HASH)
        @query_hash = DB_HASH.clone
        @query_hash[:name] = "another_name"
        @query_hash[:description] = "modified description"
      end

      context "when update is true" do
        it "updates the existing template" do
          record = CloudTemplate.find_or_create_by_template(@query_hash, true)
          record.id.should eq @existing_record.id
          record.name.should eq @query_hash[:name]
          record.template.should eq DB_HASH[:template]
          record.description.should eq @query_hash[:description]
        end
      end

      context "when update is false" do
        it "finds the existing template regardless the new name or description" do
          record = CloudTemplate.find_or_create_by_template(@query_hash)
          record.id.should eq @existing_record.id
          record.name.should eq DB_HASH[:name]
          record.template.should eq DB_HASH[:template]
          record.description.should eq DB_HASH[:description]
        end
      end
    end
  end
end
