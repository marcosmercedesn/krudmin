Krudmin::Config.with do |config|
  # The parent controller class for all Krudmin controllers.
  # Set to your application's base controller to inherit authentication and helpers.
  config.parent_controller = "ApplicationController"

  # Root path for the admin panel (route helper symbol or string).
  # config.krudmin_root_path = :admin_root_path

  # Theme and layout.
  config.layout = "krudmin/core_theme"

  # SimpleForm wrappers (must match wrappers in simple_form_bootstrap.rb).
  config.form_wrapper = :horizontal_form
  config.modal_form_wrapper = :vertical_form

  # Authentication: a before_action method that ensures the user is logged in.
  # config.require_authenticated_user_method = :authenticate_user!

  # Current user accessor (called in controller context).
  # config.current_user_method { current_user }

  # Profile and logout paths for the header menu.
  # config.edit_profile_path = "/admin/profile"
  # config.logout_path = "/users/sign_out"

  # Pagination position: :top, :bottom, or :top_and_bottom
  config.paginator_position = :top

  # Enable Pundit authorization (requires policies per model).
  # config.pundit_enabled = true

  # Login page message (supports HTML).
  # config.login_screen_intro_message = "Welcome to the Admin Panel"

  # Navigation menu.
  # config.navigation_menu = -> {
  #   Krudmin::NavigationMenu.configure do |menu, user|
  #     menu.node label: "Products", resource: "product", module_path: :admin, icon: :box
  #   end
  # }
end
