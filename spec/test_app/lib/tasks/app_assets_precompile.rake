namespace :app do
  namespace :assets do
    desc "Compatibility alias for assets precompile"
    task precompile: "assets:precompile"
  end
end
