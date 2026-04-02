require "spec_helper"

require "#{Dir.pwd}/lib/config"
require "#{Dir.pwd}/lib/krudmin/audit/base_backend"
require "#{Dir.pwd}/lib/krudmin/audit/null_backend"
require "#{Dir.pwd}/lib/krudmin/audit/krudmin_backend"
require "#{Dir.pwd}/lib/krudmin/audit/paper_trail_backend"
require "#{Dir.pwd}/lib/krudmin/audit/custom_backend"
require "#{Dir.pwd}/lib/krudmin/audit"

describe Krudmin::Audit do
  let(:record_double) do
    double("record",
      class: double(name: "Car"),
      id: 42,
      previous_changes: { "name" => ["Old", "New"], "updated_at" => [nil, Time.now] }
    )
  end

  let(:user_double) { double("user", class: double(name: "User"), id: 1) }
  let(:backend) { Krudmin::Audit::NullBackend.new }

  before do
    allow(Krudmin::Config).to receive(:audit_enabled?).and_return(true)
    allow(Krudmin::Config).to receive(:audit_backend_instance).and_return(backend)
    allow(Krudmin::Config).to receive(:audit_excluded_attributes).and_return(%i[updated_at created_at])
  end

  after do
    allow(Krudmin::Config).to receive(:audit_enabled?).and_call_original
    allow(Krudmin::Config).to receive(:audit_backend_instance).and_call_original
    allow(Krudmin::Config).to receive(:audit_excluded_attributes).and_call_original
  end

  describe ".record" do
    it "delegates to the backend with a structured payload" do
      expect(backend).to receive(:record).with(hash_including(
        auditable_type: "Car",
        auditable_id: 42,
        action: "update"
      ))

      described_class.record(event: :update, record: record_double, user: user_double, changes: { "name" => ["Old", "New"] })
    end

    it "includes user info in payload" do
      expect(backend).to receive(:record).with(hash_including(
        user_type: "User",
        user_id: 1
      ))

      described_class.record(event: :create, record: record_double, user: user_double, changes: {})
    end

    it "returns nil when audit is disabled" do
      allow(Krudmin::Config).to receive(:audit_enabled?).and_return(false)

      result = described_class.record(event: :update, record: record_double)
      expect(result).to be_nil
    end

    it "returns the payload on success" do
      allow(backend).to receive(:record)

      result = described_class.record(event: :update, record: record_double, changes: {})
      expect(result).to be_a(Hash)
      expect(result[:action]).to eq("update")
    end

    it "handles nil user gracefully" do
      allow(backend).to receive(:record)

      result = described_class.record(event: :create, record: record_double, user: nil, changes: {})
      expect(result[:user_type]).to be_nil
      expect(result[:user_id]).to be_nil
    end
  end

  describe ".entries_for" do
    it "delegates to the backend" do
      entries = [double("entry")]
      expect(backend).to receive(:entries_for).with(record_double, limit: 25).and_return(entries)

      expect(described_class.entries_for(record_double)).to eq(entries)
    end

    it "returns empty array when audit is disabled" do
      allow(Krudmin::Config).to receive(:audit_enabled?).and_return(false)

      expect(described_class.entries_for(record_double)).to eq([])
    end

    it "passes custom limit" do
      expect(backend).to receive(:entries_for).with(record_double, limit: 10).and_return([])

      described_class.entries_for(record_double, limit: 10)
    end
  end

  describe ".extract_changes" do
    it "filters excluded attributes" do
      changes = described_class.extract_changes(record_double)

      expect(changes).to have_key("name")
      expect(changes).not_to have_key("updated_at")
    end

    it "returns empty hash when record does not respond to previous_changes" do
      plain = double("plain")
      allow(plain).to receive(:respond_to?).with(:previous_changes).and_return(false)

      expect(described_class.extract_changes(plain)).to eq({})
    end
  end
end
