class Renegotiation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer,    class_name: "User"
  belongs_to :supplier, class_name: "User"

  has_many :discount_target_histories, dependent: :destroy
  belongs_to :active_discount_target_version,
             class_name: 'DiscountTargetHistory',
             optional: true

  validates :tone,       presence: true
  validates :min_target, presence: true
  validates :max_target, presence: true
  validates :current_target_discount_percentage,
            numericality: { in: 0..100 },
            allow_nil: true
  validates :current_min_discount_percentage,
            numericality: { in: 0..100 },
            allow_nil: true

  # SCOPES (reuse queries in one line)
  scope :in_period,      ->(range)       { range ? where(created_at: range) : all }
  scope :pending,        ->              { where(status: 'pending') }
  scope :ongoing,        ->              { where(status: %w[ongoing initialized]) }
  scope :human_required, ->              { where(status: 'human_required') }
  scope :completed,      ->              { where(status: 'done') }

  # BUSINESS METHODS

  def lock_targets!(target_percentage, min_percentage, user)
    new_version = discount_target_histories.create!(
      target_discount_percentage: target_percentage,
      min_discount_percentage:    min_percentage,
      set_by_user:                user,
      set_at:                     Time.current,
      version_number:             next_version_number,
      is_active:                  true
    )

    discount_target_histories.where.not(id: new_version.id)
                             .update_all(is_active: false)

    update!(
      current_target_discount_percentage:   target_percentage,
      current_min_discount_percentage:      min_percentage,
      discount_targets_locked:              true,
      active_discount_target_version:       new_version
    )

    new_version
  end

  def unlock_targets!
    update!(
      discount_targets_locked:         false,
      active_discount_target_version:  nil
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
    (discount_target_histories.maximum(:version_number) || 0) + 1
  end
end
