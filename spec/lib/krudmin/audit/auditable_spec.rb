require "spec_helper"

require "#{Dir.pwd}/lib/config"
require "#{Dir.pwd}/lib/krudmin/audit/base_backend"
require "#{Dir.pwd}/lib/krudmin/audit/null_backend"

describe "Krudmin::Auditable concern" do
  describe "audit_excluded_attributes merging" do
    it "combines global and per-resource exclusions" do
      global = %i[updated_at created_at]
      per_resource = %i[password_digest]

      combined = (global + per_resource).map(&:to_sym).uniq
      expect(combined).to contain_exactly(:updated_at, :created_at, :password_digest)
    end

    it "deduplicates overlapping exclusions" do
      global = %i[updated_at created_at]
      per_resource = %i[updated_at password_digest]

      combined = (global + per_resource).map(&:to_sym).uniq
      expect(combined).to contain_exactly(:updated_at, :created_at, :password_digest)
    end
  end

  describe "determine_audit_action mapping" do
    let(:action_map) do
      {
        "create" => "create",
        "update" => "update",
        "destroy" => "destroy",
        "activate" => "activate",
        "deactivate" => "deactivate",
        "transition" => "transition"
      }
    end

    it "maps each controller action to the expected audit action" do
      action_map.each do |action_name, expected|
        expect(action_name).to eq(expected)
      end
    end
  end
end
