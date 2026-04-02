require_relative "attribute"
require_relative "attribute_collection"
require_relative "../constants_to_methods_exposer"

module Krudmin
  module ResourceManagers
    class Base
      include Enumerable
      extend Krudmin::ConstantsToMethodsExposer

      class ModelNotFound < StandardError; end
      class InvalidCustomAction < StandardError; end

      delegate :each, :total_pages, :current_page, :limit_value, to: :items

      MODEL_CLASSNAME = nil
      LISTABLE_ATTRIBUTES = []
      EDITABLE_ATTRIBUTES = []
      SEARCHABLE_ATTRIBUTES = []
      DISPLAYABLE_ATTRIBUTES = []
      LOOKUP_ATTRIBUTES = []
      LISTABLE_ACTIONS = [:show, :edit, :destroy]
      ORDER_BY = []
      LISTABLE_INCLUDES = []
      RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :id
      RESOURCE_LABEL = ""
      RESOURCES_LABEL = ""
      ATTRIBUTE_TYPES = {}
      PRESENTATION_METADATA = {}
      REMOTE_CRUD = false
      INLINE_EDITABLE_ATTRIBUTES = []
      PAGINATOR_POSITION = nil
      BULK_ACTIONS = []
      DASHBOARD_SCOPES = {}
      DASHBOARD_COLUMNS = {}
      AUDIT_EXCLUDED_ATTRIBUTES = []

      RESERVED_ACTION_NAMES = %i[index show new edit create update destroy].freeze
      VALID_CUSTOM_ACTION_OPTIONS = %i[label icon method confirm class turbo authorize placement if route presenter_options].freeze
      VALID_PLACEMENTS = %i[list toolbar both].freeze
      VALID_HTTP_METHODS = %i[get post put patch delete].freeze

      constantized_methods :searchable_attributes, :resource_label, :resources_label, :model_classname, :listable_actions, :order_by, :remote_crud
      constantized_methods :listable_includes, :resource_instance_label_attribute, :presentation_metadata, :displayable_attributes, :lookup_attributes, :inline_editable_attributes, :bulk_actions, :dashboard_scopes, :dashboard_columns

      # --- Custom Actions DSL ---

      def self.custom_actions_registry
        @custom_actions_registry ||= {}
      end

      def self.inherited(subclass)
        super
        subclass.instance_variable_set(:@custom_actions_registry, custom_actions_registry.dup)
      end

      def self.custom_action(name, options = {})
        name = name.to_sym
        validate_custom_action!(name, options)

        placement = normalize_placement(options.fetch(:placement, :list))

        custom_actions_registry[name] = {
          name: name,
          label: options.fetch(:label, name.to_s.humanize),
          icon: options[:icon],
          method: options.fetch(:method, :post).to_sym,
          confirm: options[:confirm],
          class: options.fetch(:class, "btn-outline-primary"),
          turbo: options.fetch(:turbo, true),
          authorize: options.fetch(:authorize, true),
          placement: placement,
          if: options[:if],
          route: options[:route],
          presenter_options: options.fetch(:presenter_options, {})
        }.freeze
      end

      def self.custom_actions
        custom_actions_registry.values
      end

      def custom_actions
        self.class.custom_actions
      end

      def custom_action_for(name)
        self.class.custom_actions_registry[name.to_sym]
      end

      def custom_action?(name)
        self.class.custom_actions_registry.key?(name.to_sym)
      end

      def member_action_path(view_context, resource, action_name)
        definition = custom_action_for(action_name)
        route_opt = definition && definition[:route]

        if route_opt.respond_to?(:call)
          return view_context.instance_exec(resource, &route_opt)
        elsif route_opt.is_a?(Symbol) || route_opt.is_a?(String)
          return view_context.send(route_opt, resource)
        end

        resource_name = model_classname.underscore
        action = action_name.to_s

        candidates = _build_path_candidates(action, resource_name)

        candidates.each do |helper_name|
          if view_context.respond_to?(helper_name, true)
            return view_context.send(helper_name, resource)
          end
        end

        raise "No route helper found for custom action :#{action_name}. " \
              "Add a member route or pass a `route:` option. " \
              "Tried: #{candidates.join(', ')}"
      end

      class << self
        private

        def validate_custom_action!(name, options)
          unless name.to_s.match?(/\A[a-z_][a-z0-9_]*\z/)
            raise InvalidCustomAction, "Custom action name :#{name} is not a valid Ruby method name"
          end

          if RESERVED_ACTION_NAMES.include?(name)
            raise InvalidCustomAction, "Custom action name :#{name} conflicts with a reserved controller action. Choose a different name."
          end

          if custom_actions_registry.key?(name)
            raise InvalidCustomAction, "Duplicate custom action :#{name} on #{self.name}. Each action must be unique."
          end

          unknown_keys = options.keys.map(&:to_sym) - VALID_CUSTOM_ACTION_OPTIONS
          if unknown_keys.any?
            raise InvalidCustomAction, "Unknown option(s) #{unknown_keys.inspect} for custom action :#{name}. " \
                                       "Valid options: #{VALID_CUSTOM_ACTION_OPTIONS.inspect}"
          end

          if options[:method] && !VALID_HTTP_METHODS.include?(options[:method].to_sym)
            raise InvalidCustomAction, "Invalid HTTP method :#{options[:method]} for custom action :#{name}. " \
                                       "Valid methods: #{VALID_HTTP_METHODS.inspect}"
          end

          if options[:placement]
            placements = Array(options[:placement]).map(&:to_sym)
            invalid = placements - VALID_PLACEMENTS
            if invalid.any?
              raise InvalidCustomAction, "Invalid placement #{invalid.inspect} for custom action :#{name}. " \
                                         "Valid placements: #{VALID_PLACEMENTS.inspect}"
            end
          end

          if options[:route] && !options[:route].respond_to?(:call) && !options[:route].is_a?(Symbol) && !options[:route].is_a?(String)
            raise InvalidCustomAction, "Invalid :route option for custom action :#{name}. " \
                                       "Must be a Proc, Symbol, or String."
          end
        end

        def normalize_placement(placement)
          return Array(placement).map(&:to_sym) if placement.is_a?(Array)
          return %i[list toolbar] if placement.to_sym == :both
          [placement.to_sym]
        end
      end

      private

      def _build_path_candidates(action, resource_name)
        singular = resource_name.singularize
        plural = resource_name.pluralize
        namespace = self.class.name.to_s.gsub(/ResourceManager\z/, "").underscore.gsub(%r{/$}, "").presence

        bases = [singular, plural].uniq
        prefixes = namespace ? ["#{namespace}_", ""] : [""]

        candidates = []
        prefixes.each do |prefix|
          bases.each do |base|
            candidates << "#{prefix}#{action}_#{base}_path"
            candidates << "#{action}_#{prefix}#{base}_path"
          end
        end

        candidates.uniq
      end

      public

      def field_for(field, model = nil, root: nil)
        field_class_for(field, root).new_field(model)
      end

      def field_class_for(field, root = nil)
        resource_attributes.attribute_for(field, root)
      end

      def model_label(given_model)
        given_model.send(resource_instance_label_attribute)
      end

      def self.editable_attributes
        new.editable_attributes
      end

      def self.displayable_attributes
        new.displayable_attributes
      end

      def label_for(given_model)
        given_model.send(resource_instance_label_attribute)
      end

      def items
        @items ||= list_scope
      end

      def scope
        model_class.all
      end

      def model_class
        @model_class ||= model_classname.constantize
      end

      def self.model_class
        self::MODEL_CLASSNAME.constantize
      rescue NoMethodError
        fail ModelNotFound.new("undefined model for Resource Manager `#{name}`")
      end

      def paginator_on_top?
        paginator_position == :top || paginator_position == :top_and_bottom
      end

      def paginator_on_bottom?
        paginator_position == :bottom || paginator_position == :top_and_bottom
      end

      def bulk_actions?
        bulk_actions.any?
      end

      def dashboard_relation(scope_name = nil, relation:, user:, context: nil)
        return relation if scope_name.blank?

        definition = dashboard_scopes.fetch(scope_name.to_sym) do
          raise ArgumentError, "Unknown dashboard scope `#{scope_name}` for #{self.class.name}"
        end

        if definition.is_a?(Proc)
          instance_exec(relation, user, context, &definition)
        else
          public_send(definition, relation, user, context)
        end
      end

      def dashboard_columns_for(name = nil)
        return Array(name) if name.is_a?(Array)
        return listable_attributes if name.blank?

        dashboard_columns.fetch(name.to_sym) do
          raise ArgumentError, "Unknown dashboard columns `#{name}` for #{self.class.name}"
        end
      end

      def paginator_position
        self.class::PAGINATOR_POSITION || Krudmin::Config.paginator_position
      end

      private

      def list_scope
        scope.includes(listable_includes).order(order_by)
      end

      delegate :attribute_types, :permitted_attributes, :editable_attributes, :listable_attributes, to: :resource_attributes
      delegate :grouped_attributes, :displayable_attributes, :lookup_attributes, :searchable_attributes, :find_type_for, :inline_editable?, to: :resource_attributes

      def resource_attributes
        @resource_attributes ||= Krudmin::ResourceManagers::AttributeCollection.new(model_class,
                                                                                   self.class::ATTRIBUTE_TYPES,
                                                                                   self.class::EDITABLE_ATTRIBUTES,
                                                                                   self.class::LISTABLE_ATTRIBUTES,
                                                                                   self.class::SEARCHABLE_ATTRIBUTES,
                                                                                   self.class::DISPLAYABLE_ATTRIBUTES,
                                                                                   self.class::PRESENTATION_METADATA,
                                                                                   self.class::LOOKUP_ATTRIBUTES,
                                                                                   self.class::INLINE_EDITABLE_ATTRIBUTES)
      end
    end
  end
end
