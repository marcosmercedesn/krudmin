require_relative "../generator_spec_helper"
require "generators/krudmin/resource/resource_generator"

RSpec.describe Krudmin::Generators::ResourceGenerator do
  include GeneratorSpecHelper

  describe "with default options" do
    before { run_generator %w[Product name:string price:decimal active:boolean] }

    it "creates a resource manager" do
      expect(file_exists?("app/resource_managers/products_resource_manager.rb")).to be true

      content = file_content("app/resource_managers/products_resource_manager.rb")
      expect(content).to include("class ProductsResourceManager < Krudmin::ResourceManagers::Base")
      expect(content).to include('MODEL_CLASSNAME = "Product"')
      expect(content).to include(":name")
      expect(content).to include(":price")
      expect(content).to include(":active")
    end

    it "creates a controller" do
      expect(file_exists?("app/controllers/admin/products_controller.rb")).to be true

      content = file_content("app/controllers/admin/products_controller.rb")
      expect(content).to include("class Admin::ProductsController < Krudmin::ApplicationController")
    end

    it "creates a resource manager spec" do
      expect(file_exists?("spec/resource_managers/products_resource_manager_spec.rb")).to be true

      content = file_content("spec/resource_managers/products_resource_manager_spec.rb")
      expect(content).to include("RSpec.describe ProductsResourceManager")
      expect(content).to include('MODEL_CLASSNAME')
    end

    it "creates a controller spec" do
      expect(file_exists?("spec/controllers/admin/products_controller_spec.rb")).to be true

      content = file_content("spec/controllers/admin/products_controller_spec.rb")
      expect(content).to include("RSpec.describe Admin::ProductsController")
    end

    it "injects routes" do
      expect(file_exists?("config/routes.rb")).to be true

      content = file_content("config/routes.rb")
      expect(content).to include("resources :products")
      expect(content).to include("post :activate")
      expect(content).to include("post :deactivate")
    end
  end

  describe "with --skip-routes" do
    before do
      FileUtils.mkdir_p(File.join(destination_root, "config"))
      File.write(File.join(destination_root, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      run_generator %w[Product name:string --skip-routes]
    end

    it "does not modify routes" do
      content = file_content("config/routes.rb")
      expect(content).not_to include("resources :products")
    end
  end

  describe "with --skip-specs" do
    before { run_generator %w[Product name:string --skip-specs] }

    it "does not create specs" do
      expect(file_exists?("spec/resource_managers/products_resource_manager_spec.rb")).to be false
      expect(file_exists?("spec/controllers/admin/products_controller_spec.rb")).to be false
    end
  end

  describe "with --no-namespace" do
    before { run_generator %w[Product name:string --namespace=] }

    it "creates controller without namespace" do
      expect(file_exists?("app/controllers/products_controller.rb")).to be true

      content = file_content("app/controllers/products_controller.rb")
      expect(content).to include("class ProductsController < Krudmin::ApplicationController")
    end
  end

  describe "with --policy" do
    before { run_generator %w[Product name:string --policy] }

    it "creates a policy file" do
      expect(file_exists?("app/policies/product_policy.rb")).to be true

      content = file_content("app/policies/product_policy.rb")
      expect(content).to include("class ProductPolicy < ApplicationPolicy")
    end
  end
end
