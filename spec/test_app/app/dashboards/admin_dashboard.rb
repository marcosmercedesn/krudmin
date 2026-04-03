class AdminDashboard < Krudmin::Dashboard
  page_title "Operations Dashboard"
  page_description "A default Krudmin dashboard showing how ResourceManager-backed widgets inherit authorization and scoping from the same resources used by CRUD screens."

  toolbar do |b|
              b.link admin_cars_path, label: "Browse Cars", icon: "car-front"
              b.link car_brands_path, label: "Browse Brands", icon: :list
              b.link docs_path, label: "Docs", icon: :copy
  end

  widget :count,
         resource: CarsResourceManager,
         label: "Total Cars",
         icon: "car-front",
         tone: :primary,
         background: :slate,
         description: "All authorized cars in the system.",
         path: :admin_cars_path

  widget :count,
         resource: CarsResourceManager,
         label: "Active Cars",
         icon: "check-circle",
         tone: :success,
         background: :mint,
         scope: :active,
         description: "Cars currently marked active.",
         path: :admin_cars_path,
         grid: "col-12 col-md-6 col-xl-3"

  widget :count,
         resource: CarsResourceManager,
         label: "Inactive Cars",
         icon: "slash-circle",
         tone: :warning,
         background: :sand,
         scope: :inactive,
         description: "Cars currently marked inactive.",
         path: :admin_cars_path,
         grid: "col-12 col-md-6 col-xl-3"

  widget :count,
         resource: CarBrandsResourceManager,
         label: "Car Brands",
         icon: :tags,
         tone: :danger,
         background: :rose,
         description: "Available brands referenced by the catalog.",
         path: :car_brands_path,
         grid: "col-12 col-md-6 col-xl-3"

  widget :chart,
         resource: CarsResourceManager,
         label: "Transmission Mix",
         description: "Distribution of authorized cars by transmission type.",
         group_by: :transmission,
         tone: :primary,
         background: :ocean,
         path: :admin_cars_path

  widget :chart,
         resource: CarsResourceManager,
         label: "Activation Status",
         description: "How the current inventory is split between active and inactive.",
         group_by: :active,
         tone: :success,
         background: :indigo,
         path: :admin_cars_path

  widget :chart,
         resource: CarsResourceManager,
         label: "Cars Added by Month",
         description: "A simple time-bucketed chart based on creation date.",
         group_by: :created_at,
         period: :month,
         tone: :warning,
         background: :charcoal,
         path: :admin_cars_path

  widget :table,
         resource: CarsResourceManager,
         label: "Recent Cars",
         description: "A resource-manager-backed table using a dashboard column preset.",
         scope: :recent,
         background: :default,
         columns: :showroom,
         limit: 6,
         path: :admin_cars_path

  widget :list,
         resource: CarsResourceManager,
         label: "Latest Active Cars",
         description: "Recent active cars with their release year.",
         scope: :active,
         background: :slate,
         secondary_attribute: :year,
         limit: 6,
         path: :admin_cars_path,
         grid: "col-12 col-xl-4"

  widget :list,
         resource: CarBrandsResourceManager,
         label: "Brand Catalog",
         description: "A compact list widget backed by a second resource manager.",
         scope: :alphabetic,
         background: :ocean,
         secondary_attribute: :created_at,
         limit: 8,
         path: :car_brands_path,
         grid: "col-12 col-xl-4"
end