namespace :krudmin do
  namespace :assets do
    desc "Build Propshaft-ready Krudmin assets"
    task build: :environment do
      Krudmin::AssetBuilder.build!(app_root: Rails.root)
    end
  end
end

Rake::Task["assets:precompile"].enhance(["krudmin:assets:build"]) if Rake::Task.task_defined?("assets:precompile")