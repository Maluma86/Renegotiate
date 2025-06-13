class Renegotiation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer,    class_name: "User"
  belongs_to :supplier, class_name: "User"

  # DISCOUNT TARGET ASSOCIATIONS
  has_many :discount_target_histories, dependent: :destroy
  belongs_to :active_discount_target_version,
             class_name: 'DiscountTargetHistory',
             optional: true

  validates :tone,       presence: true
  validates :min_target, presence: true
  validates :max_target, presence: true

  # DISCOUNT TARGET VALIDATIONS
  validates :current_target_discount_percentage,
            numericality: { in: 0..100 },
            allow_nil: true

  validates :current_min_discount_percentage,
            numericality: { in: 0..100 },
            allow_nil: true

  # DISCOUNT TARGET BUSINESS METHODS

  def lock_targets!(target_percentage, min_percentage, user)
    # Create new history record
    new_version = discount_target_histories.create!(
      target_discount_percentage: target_percentage,
      min_discount_percentage: min_percentage,
      set_by_user: user,
      set_at: Time.current,
      version_number: next_version_number,
      is_active: true
    )

    # Deactivate previous versions
    discount_target_histories.where.not(id: new_version.id)
                             .update_all(is_active: false)

    # Update current state
    update!(
      current_target_discount_percentage: target_percentage,
      current_min_discount_percentage: min_percentage,
      discount_targets_locked: true,
      active_discount_target_version: new_version
    )
    
    new_version
  end

  def unlock_targets!
    update!(
      discount_targets_locked: false,
      active_discount_target_version: nil
    )
  end

  def can_modify_targets?
    !discount_targets_locked?
  end

  def targets_set?
    current_target_discount_percentage.present? &&
    current_min_discount_percentage.present?
  end

  private

  def next_version_number
    # Force fresh database query to avoid caching issues
    ((DiscountTargetHistory.where(renegotiation_id: id).maximum(:version_number)) || 0) + 1
  end
end
