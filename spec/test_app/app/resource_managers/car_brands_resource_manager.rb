class CarBrandsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "CarBrand"

  LISTABLE_ACTIONS = [:show, :edit, :destroy]
  ORDER_BY = [:description]
  RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :description
  RESOURCE_LABEL = "Car Brand"
  RESOURCES_LABEL = "Car Brands"
  REMOTE_CRUD = true
  BULK_ACTIONS = [:destroy]
  DASHBOARD_SCOPES = {
    recent: ->(relation, _user, _context) { relation.order(created_at: :desc) },
    alphabetic: ->(relation, _user, _context) { relation.order(description: :asc) }
  }
  DASHBOARD_COLUMNS = {
    compact: [:description, :created_at]
  }
  # INLINE_EDITABLE_ATTRIBUTES = [:description]
end
