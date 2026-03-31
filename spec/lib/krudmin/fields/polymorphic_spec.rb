require "spec_helper"
require "#{Dir.pwd}/lib/krudmin/fields/base"
require "#{Dir.pwd}/lib/krudmin/fields/polymorphic"

describe Krudmin::Fields::Polymorphic do
  let(:options) { { type_options: ["Car", "CarBrand"] } }

  subject { described_class.new(:commentable_type, model, options) }

  describe "attribute inference" do
    let(:model) { double(commentable_type: "Car", commentable_id: 42, commentable: double(to_s: "Camry")) }

    it "infers the association name from the attribute" do
      expect(subject.association_name).to eq(:commentable)
    end

    it "infers the type attribute" do
      expect(subject.type_attribute).to eq(:commentable_type)
    end

    it "infers the id attribute" do
      expect(subject.id_attribute).to eq(:commentable_id)
    end

    it "returns the type value from the model" do
      expect(subject.type_value).to eq("Car")
    end

    it "returns the id value from the model" do
      expect(subject.id_value).to eq(42)
    end
  end

  describe "with an associated record" do
    let(:associated) { double(to_s: "Toyota Camry") }
    let(:model) { double(commentable_type: "Car", commentable_id: 1, commentable: associated) }

    it "returns the associated record" do
      expect(subject.associated_record).to eq(associated)
    end

    it "displays the associated record label" do
      expect(subject.to_s).to eq("Toyota Camry")
    end

    context "with custom label_method" do
      let(:options) { { type_options: ["Car"], label_method: :name } }
      let(:associated) { double(name: "Camry 2024") }

      it "uses the custom label method" do
        expect(subject.to_s).to eq("Camry 2024")
      end
    end
  end

  describe "with type but no association method" do
    let(:model) { double(commentable_type: "Car", commentable_id: 7) }

    before do
      allow(model).to receive(:commentable).and_raise(NoMethodError)
    end

    it "falls back to type#id format" do
      expect(subject.to_s).to eq("Car #7")
    end
  end

  describe "without any association" do
    let(:model) { double(commentable_type: nil, commentable_id: nil) }

    it "displays dash" do
      expect(subject.to_s).to eq("-")
    end
  end

  describe "type_options_for_select" do
    let(:model) { double(commentable_type: nil, commentable_id: nil) }

    it "formats type options for a select dropdown" do
      expect(subject.type_options_for_select).to eq([
        ["Car", "Car"],
        ["Car brand", "CarBrand"]
      ])
    end
  end

  describe "permitted_attribute" do
    let(:model) { double(commentable_type: nil, commentable_id: nil) }

    it "returns both type and id attributes" do
      expect(subject.permitted_attribute).to eq([:commentable_type, :commentable_id])
    end
  end

  describe "type_as_hash" do
    it "expands to type and id entries" do
      result = described_class.type_as_hash(:commentable_type, { type_options: ["Car"] })
      expect(result.keys).to eq([:commentable_type, :commentable_id])
    end
  end

  describe "field_type" do
    it "returns polymorphic" do
      expect(described_class.field_type).to eq("polymorphic")
    end
  end

  describe "with custom association_name" do
    let(:options) { { association_name: :owner, type_options: ["User", "Admin"] } }
    let(:model) { double(owner_type: "User", owner_id: 5, owner: double(to_s: "John")) }

    subject { described_class.new(:owner_type, model, options) }

    it "uses the custom association name" do
      expect(subject.association_name).to eq(:owner)
      expect(subject.type_attribute).to eq(:owner_type)
      expect(subject.id_attribute).to eq(:owner_id)
      expect(subject.to_s).to eq("John")
    end
  end
end
