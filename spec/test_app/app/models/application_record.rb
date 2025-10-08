class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.ransackable_associations(*, **) = reflections.keys
  def self.ransackable_attributes(*, **) = attribute_names
end
