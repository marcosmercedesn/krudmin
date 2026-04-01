# Different ways to interact with Krudmin initializer

Krudmin::Config.with do |config|
  # config.current_user_method(&:current_user)
  # config.current_user_method(&:current_krudmin_profile)
  config.edit_profile_path = "/krudmin/users"
  config.logout_path = "/krudmin/user/sign_out"

  config.navigation_menu = -> {
    Krudmin::NavigationMenu.configure do |menu, user|
      menu.link label: "Dashboard", link: :admin_dashboard_path, module_path: :admin, icon: :dashboard
      menu.node label: "Cars", resource: "car", module_path: :admin, icon: :car, visible_if: -> { CarPolicy.new(nil, nil).index? }
      menu.node label: "Car Brands", resource: "car_brand", icon: :car
      # menu.node label: "Users",  resource: "user", module_path: :krudmin, icon: :users
      menu.link label: "Customs",  link: :admin_customs_path, module_path: :admin, icon: :gear
      menu.link label: "Documentation",  link: :docs_path, icon: :copy
    end
  }

  config.parent_controller = "ApplicationController"
end

Krudmin::config do |cfg|
  cfg.krudmin_root_path = :admin_dashboard_path
  cfg.pundit_enabled = true
  cfg.layout = "krudmin/core_theme_top_navbar"
  cfg.form_wrapper = :horizontal_form
  cfg.modal_form_wrapper = :vertical_form
  cfg.paginator_position = :top_bottom
  cfg.login_screen_intro_message = "<login_screen_intro_message> \n CONFIGURE ON KURMIN INITIALIZER"
  cfg.require_authenticated_user_method = :authenticate_krudmin_profile!
end

config = Krudmin::config
