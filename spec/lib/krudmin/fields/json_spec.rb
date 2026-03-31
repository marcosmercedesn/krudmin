require "spec_helper"
require "json"
require "#{Dir.pwd}/lib/krudmin/fields/base"
require "#{Dir.pwd}/lib/krudmin/fields/json"

describe Krudmin::Fields::Json do
  let(:options) { {} }

  subject { described_class.new(:metadata, model, options) }

  describe "with hash data" do
    let(:data) { { "color" => "red", "size" => "large", "count" => 5 } }
    let(:model) { double(metadata: data) }

    it "returns the hash as value" do
      expect(subject.value).to eq(data)
    end

    it "formats as pretty JSON" do
      expect(subject.to_s).to include('"color": "red"')
      expect(subject.to_s).to include('"size": "large"')
    end

    it "returns flat pairs" do
      expect(subject.flat_pairs).to eq([["color", "red"], ["size", "large"], ["count", 5]])
    end

    it "reports as attached data" do
      expect(subject.data).to eq(data)
    end
  end

  describe "with array data" do
    let(:data) { [1, 2, 3] }
    let(:model) { double(metadata: data) }

    it "returns the array as value" do
      expect(subject.value).to eq([1, 2, 3])
    end

    it "formats as pretty JSON" do
      expect(subject.to_s).to include("1")
    end

    it "returns empty flat_pairs for non-hash" do
      expect(subject.flat_pairs).to eq([])
    end
  end

  describe "with nested hash data" do
    let(:data) { { "settings" => { "theme" => "dark" }, "tags" => ["a", "b"] } }
    let(:model) { double(metadata: data) }

    it "serializes nested values in flat_pairs" do
      pairs = subject.flat_pairs
      expect(pairs[0][0]).to eq("settings")
      expect(pairs[0][1]).to eq('{"theme":"dark"}')
      expect(pairs[1][0]).to eq("tags")
      expect(pairs[1][1]).to eq('["a","b"]')
    end
  end

  describe "with nil data" do
    let(:model) { double(metadata: nil) }

    it "displays dash" do
      expect(subject.to_s).to eq("-")
    end

    it "returns empty flat_pairs" do
      expect(subject.flat_pairs).to eq([])
    end
  end

  describe "parse" do
    let(:model) { double(metadata: nil) }

    it "parses a JSON string into a hash" do
      expect(subject.parse('{"key":"value"}')).to eq({ "key" => "value" })
    end

    it "parses a JSON array string" do
      expect(subject.parse('[1,2,3]')).to eq([1, 2, 3])
    end

    it "passes through a hash unchanged" do
      hash = { "a" => 1 }
      expect(subject.parse(hash)).to eq(hash)
    end

    it "passes through an array unchanged" do
      arr = [1, 2]
      expect(subject.parse(arr)).to eq(arr)
    end

    it "returns nil for blank string" do
      expect(subject.parse("")).to be_nil
      expect(subject.parse(nil)).to be_nil
    end

    it "returns raw string for invalid JSON" do
      expect(subject.parse("not json")).to eq("not json")
    end
  end

  describe "options" do
    let(:model) { double(metadata: {}) }

    context "default" do
      it "defaults to textarea editing" do
        expect(subject.editable_as_textarea?).to be true
      end

      it "defaults to 8 rows" do
        expect(subject.rows).to eq(8)
      end
    end

    context "custom rows" do
      let(:options) { { rows: 15 } }

      it "uses the custom row count" do
        expect(subject.rows).to eq(15)
      end
    end

    context "textarea disabled" do
      let(:options) { { textarea: false } }

      it "reports textarea as disabled" do
        expect(subject.editable_as_textarea?).to be false
      end
    end
  end

  describe "field_type" do
    it "returns json" do
      expect(described_class.field_type).to eq("json")
    end
  end

  describe "search predicates" do
    it "supports cont and eq" do
      expect(described_class::SEARCH_PREDICATES).to eq([:cont, :eq])
    end
  end
end
