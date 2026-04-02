class CarsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "Car"

  EDITABLE_ATTRIBUTES = {
    general: [:active, :description, :created_at, :release_date],
    activation: [:model, :year, :car_brand_id, :transmission],
    passengers: [:passengers],
    insurance: [:car_insurance],
    owner: [:car_owner]
  }
  DISPLAYABLE_ATTRIBUTES = [:id, :model, :year, :status, :description, :transmission, :car_brand_id, :passengers, :created_at]
  SEARCHABLE_ATTRIBUTES = [:model, :year, :active, :status, :car_brand_id, :transmission, :created_at]
  LISTABLE_ACTIONS = [:show, :edit, :active, :destroy]
  LISTABLE_ATTRIBUTES = [:model, :id, :status, :car_brand_description, :year, :active, :description, :created_at]
  LISTABLE_INCLUDES = [:car_brand]
  PAGINATOR_POSITION = :bottom
  INLINE_EDITABLE_ATTRIBUTES = [:year, :active]
  BULK_ACTIONS = [:destroy, :activate, :deactivate]
  DASHBOARD_SCOPES = {
    active: ->(relation, _user, _context) { relation.active },
    inactive: ->(relation, _user, _context) { relation.inactive },
    recent: ->(relation, _user, _context) { relation.order(created_at: :desc) },
    automatic: ->(relation, _user, _context) { relation.where(transmission: transmissions[:automatic]) },
    manual: ->(relation, _user, _context) { relation.where(transmission: transmissions[:manual]) }
  }
  DASHBOARD_COLUMNS = {
    compact: [:model, :year, :active, :created_at],
    showroom: [:model, :car_brand_description, :transmission, :year, :active]
  }

  ORDER_BY = [:year]

  RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :model
  RESOURCE_LABEL = "Car"
  RESOURCES_LABEL = "Cars"

  PRESENTATION_METADATA = {
    general: { label: "General Info", class: "col-lg-6 col-md-12" },
    activation: { label: "Activation", class: "col-lg-6 col-md-12" },
    passengers: { label: "Passengers", class: "col-md-12" },
    insurance: { label: "Insurance", class: "col-md-6" },
    owner: { label: "Owner", class: "col-md-6" },
  }

  ATTRIBUTE_TYPES = {
    id: { type: :Number, padding: 10, prefix: :CK },
    model: { type: :Text, input: { rows: 2 } },
    description: { type: :RichText, show_length: 20 },
    year: :Number,
    active: { type: :Boolean, input: { label: 'Is Active'} },
    passengers: :HasMany,
    car_brand_id: { type: :BelongsTo, collection_label_field: :description, association_path: :car_brand_path, add_path: :new_car_brand, edit_path: :edit_car_brand, remote: true },
    created_at: { type: :DateTime, format: :short },
    release_date: { type: :Date, format: :short },
    transmission: { type: :EnumType, associated_options: -> { Car.transmissions } },
    status: {
      type: :StateMachine,
      transitions: {
        draft: [:submit],
        submitted: [:approve, :reject],
        approved: [:pay],
        rejected: [:submit],
        paid: []
      },
      transition_labels: {
        submit: "Submit",
        approve: "Approve",
        reject: "Reject",
        pay: "Mark as Paid"
      },
      colors: {
        draft: :secondary,
        submitted: :warning,
        approved: :success,
        paid: :info,
        rejected: :danger
      }
    },
    car_insurance: { type: :HasOne, required: true },
    car_owner: :BelongsToOne
  }

  def transmissions
    model_class.transmissions
  end
end
