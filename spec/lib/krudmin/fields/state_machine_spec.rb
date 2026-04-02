require "spec_helper"
require "active_support/all"
require "#{Dir.pwd}/lib/krudmin/fields/base"
require "#{Dir.pwd}/lib/krudmin/fields/state_machine"

describe Krudmin::Fields::StateMachine do
  let(:model) do
    Class.new do
      attr_reader :status

      def initialize(status: :draft)
        @status = status
      end

      def may_submit?
        status.to_s == "draft"
      end

      def may_approve?
        status.to_s == "submitted"
      end
    end.new(status: :draft)
  end

  subject do
    described_class.new(:status, model, {
      transitions: {
        draft: [:submit],
        submitted: [:approve]
      },
      transition_labels: {
        submit: "Submit",
      },
      colors: {
        draft: :secondary,
      }
    })
  end

  it "returns configured transition events for current state when allowed" do
    expect(subject.transition_events_for_current_state).to eq([:submit])
  end

  it "humanizes transition labels with override support" do
    expect(subject.transition_label_for(:submit)).to eq("Submit")
    expect(subject.transition_label_for(:approve)).to eq("Approve")
  end

  it "returns configured badge class for state" do
    expect(subject.badge_class_for(:draft)).to eq(:secondary)
  end
end
