class DiscountTargetHistory < ApplicationRecord
  # === ASSOCIATIONS ===
  belongs_to :renegotiation
  belongs_to :set_by_user, class_name: 'User', foreign_key: 'set_by_user_id'

  # === VALIDATIONS ===
  validates :target_discount_percentage,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100,
              message: 'must be between 0 and 100%'
            }

  validates :min_discount_percentage,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100,
              message: 'must be between 0 and 100%'
            }

  validates :set_by_user_id, presence: true
  validates :set_at, presence: true
  validates :version_number,
            presence: true,
            numericality: { greater_than: 0, only_integer: true }

  # Business logic validation: min should not be greater than target
  validate :min_not_greater_than_target

  # === SCOPES ===
  scope :active, -> { where(is_active: true) }
  scope :for_renegotiation, lambda { |renegotiation_id|
    where(renegotiation_id: renegotiation_id)
  }
  scope :ordered_by_version, -> { order(version_number: :desc) }

  # === CALLBACKS ===
  before_save :set_timestamp_if_missing

  private

  def min_not_greater_than_target
    return unless min_discount_percentage && target_discount_percentage
    return unless min_discount_percentage > target_discount_percentage

    errors.add(:min_discount_percentage,
               'cannot be greater than target discount percentage')
  end

  def set_timestamp_if_missing
    self.set_at ||= Time.current
  end
end
