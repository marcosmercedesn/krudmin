class Car < ApplicationRecord
  include Krudmin::ActivableLabeler
  include AASM

  validates :model, :year, presence: true
  validates :year, numericality: { only_integer: true }
  validates :year, length: { is: 4 }

  has_many :passengers, -> { order(:id) }
  accepts_nested_attributes_for :passengers, reject_if: :all_blank, allow_destroy: true

  has_one                         :car_insurance, dependent: :destroy
  accepts_nested_attributes_for   :car_insurance, allow_destroy: true

  belongs_to                      :car_owner, optional: true
  accepts_nested_attributes_for   :car_owner, allow_destroy: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  belongs_to :car_brand, optional: true

  enum :transmission, {automatic: 0, manual: 1}
  enum :status, {draft: 0, submitted: 1, approved: 2, rejected: 3, paid: 4}

  aasm column: :status, enum: true do
    state :draft, initial: true
    state :submitted, :approved, :rejected, :paid

    event :submit do
      transitions from: :draft, to: :submitted
    end

    event :approve do
      transitions from: :submitted, to: :approved
    end

    event :reject do
      transitions from: :submitted, to: :rejected
    end

    event :pay do
      transitions from: :approved, to: :paid
    end
  end

  delegate :description, to: :car_brand, prefix: true, allow_nil: true

  def activate!
    unless cant_be_touched?
      update_attribute(:active, true)
    else
      errors[:base] << "Can't be touched"
      false
    end
  end

  def deactivate!
    unless cant_be_touched?
      update_attribute(:active, false)
    else
      errors[:base] << "Can't be touched"
      false
    end
  end

  # There is an special trick for Camry 1989, it can't be activated or deactivated
  def cant_be_touched?
    (model == "Camry" && year == 1989)
  end

  def destroy
    super unless cant_be_touched?
  end

  def transmission=(value)
    super(value.size == 1 ? value.to_i : value)
  end
end
