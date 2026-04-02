require 'spec_helper'
require "#{Dir.pwd}/lib/config"

describe Krudmin::Config do
  let(:current_user) { double(name: "user_name", email: "user@example.com") }

  around do |example|
    original_current_user_method = described_class.current_user_method

    example.run
  ensure
    described_class.current_user_method(&original_current_user_method)
  end

  describe "with" do
    it do
      described_class.with do |config|
        config.current_user_method(&:current_user)
      end
    end
  end
end
