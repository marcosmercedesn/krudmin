class CarBrand < ApplicationRecord
  validates :description, uniqueness: true, presence: true

  has_many :cars

  scope :search_by_term, -> (term) {
    if term.present?
      where(CarBrand.arel_table[:description].matches("%#{term}%"))
    else
      where("1=1")
    end.limit(10)
  }
end
