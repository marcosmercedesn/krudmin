require "spec_helper"
require "rspec/mocks"

require "#{Dir.pwd}/lib/krudmin/fields/base"
require "#{Dir.pwd}/lib/krudmin/fields/number"
require "#{Dir.pwd}/lib/krudmin/fields/string"
require "#{Dir.pwd}/lib/krudmin/fields/associated"
require "#{Dir.pwd}/lib/krudmin/fields/has_many"
require "#{Dir.pwd}/lib/krudmin/fields/inflector"
require "#{Dir.pwd}/lib/krudmin/resource_managers/base"

describe "Krudmin::ResourceManagers::Base custom actions" do
  class Krudmin::CustomActionTestModel
    class << self
      def all; []; end
      def primary_key; "id"; end
      def column_names; []; end
      def columns_hash; {}; end
      def reflections; {}; end
    end
  end

  after(:all) do
    Krudmin.send(:remove_const, :CustomActionTestModel) if Krudmin.const_defined?(:CustomActionTestModel)
  end

  describe "custom_action macro" do
    it "registers an action with default options" do
      klass = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :generate_invoice
      end

      action = klass.custom_actions.first
      expect(action[:name]).to eq(:generate_invoice)
      expect(action[:label]).to eq("Generate invoice")
      expect(action[:method]).to eq(:post)
      expect(action[:turbo]).to be true
      expect(action[:authorize]).to be true
      expect(action[:placement]).to eq([:list])
      expect(action[:class]).to eq("btn-outline-primary")
    end

    it "registers an action with custom options" do
      klass = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :clone, label: "Clone Record", icon: :copy,
                      method: :post, confirm: "Clone this?",
                      class: "btn-success", placement: :both
      end

      action = klass.custom_actions.first
      expect(action[:name]).to eq(:clone)
      expect(action[:label]).to eq("Clone Record")
      expect(action[:icon]).to eq(:copy)
      expect(action[:confirm]).to eq("Clone this?")
      expect(action[:class]).to eq("btn-success")
      expect(action[:placement]).to eq([:list, :toolbar])
    end

    it "registers multiple actions" do
      klass = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :generate_invoice
        custom_action :clone
      end

      expect(klass.custom_actions.length).to eq(2)
      expect(klass.custom_actions.map { |a| a[:name] }).to eq([:generate_invoice, :clone])
    end

    it "normalizes :both placement to [:list, :toolbar]" do
      klass = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :archive, placement: :both
      end

      expect(klass.custom_actions.first[:placement]).to eq([:list, :toolbar])
    end

    it "supports array placement" do
      klass = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :archive, placement: [:list, :toolbar]
      end

      expect(klass.custom_actions.first[:placement]).to eq([:list, :toolbar])
    end
  end

  describe "instance accessors" do
    let(:klass) do
      Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :generate_invoice, label: "Generate Invoice", icon: :file_text
        custom_action :clone, label: "Clone"
      end
    end

    subject { klass.new }

    it "custom_actions returns all registered actions" do
      expect(subject.custom_actions.length).to eq(2)
    end

    it "custom_action_for returns a specific action" do
      action = subject.custom_action_for(:generate_invoice)
      expect(action[:label]).to eq("Generate Invoice")
      expect(action[:icon]).to eq(:file_text)
    end

    it "custom_action_for returns nil for unknown actions" do
      expect(subject.custom_action_for(:nonexistent)).to be_nil
    end

    it "custom_action? returns true for registered actions" do
      expect(subject.custom_action?(:generate_invoice)).to be true
      expect(subject.custom_action?(:clone)).to be true
    end

    it "custom_action? returns false for non-custom actions" do
      expect(subject.custom_action?(:show)).to be false
      expect(subject.custom_action?(:nonexistent)).to be false
    end
  end

  describe "inheritance" do
    it "subclasses inherit parent custom actions" do
      parent = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :generate_invoice
      end

      child = Class.new(parent) do
        custom_action :clone
      end

      expect(child.custom_actions.length).to eq(2)
      expect(parent.custom_actions.length).to eq(1)
    end

    it "child actions don't affect parent" do
      parent = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :generate_invoice
      end

      Class.new(parent) do
        custom_action :clone
      end

      expect(parent.custom_actions.map { |a| a[:name] }).to eq([:generate_invoice])
    end
  end

  describe "validation" do
    it "rejects invalid Ruby method names" do
      expect {
        Class.new(Krudmin::ResourceManagers::Base) do
          custom_action :"invalid-name"
        end
      }.to raise_error(Krudmin::ResourceManagers::Base::InvalidCustomAction, /not a valid Ruby method name/)
    end

    it "rejects reserved controller action names" do
      %i[index show new edit create update destroy].each do |reserved|
        expect {
          Class.new(Krudmin::ResourceManagers::Base) do
            custom_action reserved
          end
        }.to raise_error(Krudmin::ResourceManagers::Base::InvalidCustomAction, /conflicts with a reserved/)
      end
    end

    it "rejects duplicate action names" do
      expect {
        Class.new(Krudmin::ResourceManagers::Base) do
          custom_action :clone
          custom_action :clone
        end
      }.to raise_error(Krudmin::ResourceManagers::Base::InvalidCustomAction, /Duplicate/)
    end

    it "rejects unknown option keys" do
      expect {
        Class.new(Krudmin::ResourceManagers::Base) do
          custom_action :clone, unknown_key: true
        end
      }.to raise_error(Krudmin::ResourceManagers::Base::InvalidCustomAction, /Unknown option/)
    end

    it "rejects invalid HTTP methods" do
      expect {
        Class.new(Krudmin::ResourceManagers::Base) do
          custom_action :clone, method: :banana
        end
      }.to raise_error(Krudmin::ResourceManagers::Base::InvalidCustomAction, /Invalid HTTP method/)
    end

    it "rejects invalid placements" do
      expect {
        Class.new(Krudmin::ResourceManagers::Base) do
          custom_action :clone, placement: :sidebar
        end
      }.to raise_error(Krudmin::ResourceManagers::Base::InvalidCustomAction, /Invalid placement/)
    end

    it "rejects invalid route types" do
      expect {
        Class.new(Krudmin::ResourceManagers::Base) do
          custom_action :clone, route: 123
        end
      }.to raise_error(Krudmin::ResourceManagers::Base::InvalidCustomAction, /Invalid :route option/)
    end
  end

  describe "member_action_path" do
    let(:klass) do
      Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :generate_invoice
      end
    end

    subject { klass.new }

    it "uses a callable route when provided" do
      klass_with_route = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :generate_invoice, route: ->(resource) { "/custom/#{resource}" }
      end

      manager = klass_with_route.new
      view_context = double("view_context")
      expect(view_context).to receive(:instance_exec).with(:model).and_return("/custom/model")

      result = manager.member_action_path(view_context, :model, :generate_invoice)
      expect(result).to eq("/custom/model")
    end

    it "uses a symbol route when provided" do
      klass_with_route = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :generate_invoice, route: :my_custom_path
      end

      manager = klass_with_route.new
      view_context = double("view_context")
      expect(view_context).to receive(:send).with(:my_custom_path, :model).and_return("/custom/path")

      result = manager.member_action_path(view_context, :model, :generate_invoice)
      expect(result).to eq("/custom/path")
    end

    it "tries conventional helper names" do
      view_context = double("view_context")
      allow(view_context).to receive(:respond_to?).and_return(false)
      allow(view_context).to receive(:respond_to?).with("generate_invoice_krudmin/custom_action_test_model_path", true).and_return(true)
      allow(view_context).to receive(:send).with("generate_invoice_krudmin/custom_action_test_model_path", :model).and_return("/path")

      result = subject.member_action_path(view_context, :model, :generate_invoice)
      expect(result).to eq("/path")
    end

    it "raises when no route helper is found" do
      view_context = double("view_context")
      allow(view_context).to receive(:respond_to?).and_return(false)

      expect {
        subject.member_action_path(view_context, :model, :generate_invoice)
      }.to raise_error(RuntimeError, /No route helper found/)
    end
  end

  describe "conditional display with :if" do
    it "stores the if predicate in normalized metadata" do
      predicate = ->(resource, user, ctx) { resource.active? }
      klass = Class.new(Krudmin::ResourceManagers::Base) do
        self::MODEL_CLASSNAME = "Krudmin::CustomActionTestModel"
        custom_action :archive, if: predicate
      end

      action = klass.custom_actions.first
      expect(action[:if]).to eq(predicate)
    end
  end
end
