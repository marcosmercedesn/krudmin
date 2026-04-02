require "spec_helper"

require "#{Dir.pwd}/lib/config"
require "#{Dir.pwd}/lib/krudmin/audit/base_backend"
require "#{Dir.pwd}/lib/krudmin/audit/null_backend"
require "#{Dir.pwd}/lib/krudmin/audit/custom_backend"

describe "Krudmin::Audit backends" do
  let(:payload) do
    {
      auditable_type: "Car",
      auditable_id: 1,
      user_type: "User",
      user_id: 42,
      action: "update",
      changes: { "name" => ["Old", "New"] },
      metadata: { controller: "admin/cars", action: "update" }
    }
  end

  let(:record_double) do
    double("record", class: double(name: "Car"), id: 1)
  end

  describe Krudmin::Audit::BaseBackend do
    subject { described_class.new }

    it "raises NotImplementedError for #record" do
      expect { subject.record(payload) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for #entries_for" do
      expect { subject.entries_for(record_double) }.to raise_error(NotImplementedError)
    end
  end

  describe Krudmin::Audit::NullBackend do
    subject { described_class.new }

    it "returns nil for #record (no-op)" do
      expect(subject.record(payload)).to be_nil
    end

    it "returns empty array for #entries_for" do
      expect(subject.entries_for(record_double)).to eq([])
    end
  end

  describe Krudmin::Audit::CustomBackend do
    subject { described_class.new }

    it "delegates #record to Config.audit_recorder" do
      recorder = double("recorder")
      allow(Krudmin::Config).to receive(:audit_recorder).and_return(recorder)
      expect(recorder).to receive(:call).with(payload)

      subject.record(payload)
    end

    it "delegates #entries_for to Config.audit_entries_provider" do
      provider = double("provider")
      allow(Krudmin::Config).to receive(:audit_entries_provider).and_return(provider)
      expect(provider).to receive(:call).with(record_double, limit: 25).and_return([])

      expect(subject.entries_for(record_double)).to eq([])
    end

    it "respects the limit parameter" do
      provider = double("provider")
      allow(Krudmin::Config).to receive(:audit_entries_provider).and_return(provider)
      expect(provider).to receive(:call).with(record_double, limit: 10).and_return([])

      subject.entries_for(record_double, limit: 10)
    end
  end
end
