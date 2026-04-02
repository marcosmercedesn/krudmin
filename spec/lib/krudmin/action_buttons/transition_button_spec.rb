require "spec_helper"
require "active_support/all"
require "ostruct"

require "#{Dir.pwd}/lib/krudmin/fields/base"
require "#{Dir.pwd}/lib/krudmin/fields/state_machine"
require "#{Dir.pwd}/lib/krudmin/action_buttons/base"
require "#{Dir.pwd}/lib/krudmin/action_buttons/model_action_button"
require "#{Dir.pwd}/lib/krudmin/action_buttons/transition_button"

describe Krudmin::ActionButtons::TransitionButton do
  let(:model) { double("model") }
  let(:field) do
    double("state_machine_field",
           transition_label_for: "Submit",
           transition_allowed?: true,
           is_a?: true)
  end

  let(:manager) do
    double("manager",
           editable_attributes: [:status],
           displayable_attributes: [:status],
           listable_attributes: [:status],
           searchable_attributes: [],
           field_for: field)
  end

  let(:view_context) do
    double("view_context", krudmin_manager: manager, transition_access?: true).tap do |context|
      allow(context).to receive(:transition_path)
        .with(model, event: :submit, attribute: :status, context: :form)
        .and_return("/admin/cars/1/transition?event=submit")
    end
  end

  before do
    allow(manager).to receive(:field_class_for).with(:status).and_return(OpenStruct.new(type: Krudmin::Fields::StateMachine))
  end

  it "detects the only configured state machine attribute" do
    button = described_class.new(:form, view_context, model, :submit)

    expect(button.attribute).to eq(:status)
  end

  it "uses the state machine field label for the button" do
    button = described_class.new(:form, view_context, model, :submit)

    expect(button.button_label).to eq("Submit")
    expect(button.action_path).to eq("/admin/cars/1/transition?event=submit")
  end

  it "requires an explicit attribute when multiple state machine fields exist" do
    allow(manager).to receive(:editable_attributes).and_return([:status, :review_state])
    allow(manager).to receive(:field_class_for).with(:review_state).and_return(OpenStruct.new(type: Krudmin::Fields::StateMachine))

    expect {
      described_class.new(:form, view_context, model, :submit)
    }.to raise_error(ArgumentError, /Multiple StateMachine fields/)
  end
end
