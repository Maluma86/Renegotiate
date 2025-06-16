class Product < ApplicationRecord
  belongs_to :supplier, class_name: 'User' #this means “Treat supplier_id as a foreign key to the users table — and treat the related record as a User.”
  belongs_to :procurement, class_name: 'User'

  has_many :renegotiations

  validates :name, presence: true
  validates :category, presence: true
  validates :description, presence: true
  validates :current_price, presence: true
  validates :contract_end_date, presence: true

  # SCOPES
  # contracts ending between two dates
  scope :ending_between, ->(start_date, end_date) { where(contract_end_date: start_date..end_date) }

  # … used in the SHOW page
  def sku
    "SKU-#{id.to_s.rjust(6,'0')}"
  end

  def target_margin
    read_attribute(:target_margin) || 35
  end

  def last_year_volume
    read_attribute(:last_year_volume) || 0
  end

  def last_year_volume
    last_month_volume.to_f * 12
  end

  # WHAT IT IS : below is the function to automatically update the status.

  # Business logic for renegotiation timing
  def contract_expiring_soon?
    return false unless contract_end_date
    contract_end_date <= 6.months.from_now
  end

  # Check if product has ongoing renegotiation for user's company
  def has_ongoing_renegotiation?(user)
    # Check for ongoing renegotiation by anyone from the same company
    renegotiations.joins(:buyer)
                  .exists?(users: { company_name: user.company_name }, 
                          status: "Ongoing")
  end

  # Calculate when renegotiation becomes available (6 months before expiry)
  def next_review_date
    return nil unless contract_end_date
    # 6 months before contract expires
    contract_end_date - 6.months
  end

  # New renegotiation status method that considers user and business rules
  def renegotiation_status_for_user(user)
    return :ongoing if has_ongoing_renegotiation?(user)
    return :available if contract_expiring_soon?
    return :pending_review # Show next review date
  end

  # Check if renegotiation is allowed for this user
  def renegotiation_allowed?(user)
    return false unless contract_expiring_soon?
    return false if has_ongoing_renegotiation?(user)
    true
  end

  # New business rule-based status display for users
  def display_status_for_user(user)
    # Status based on what the user can actually do with this product
    
    # Check if user's company has any renegotiation (any status)
    latest_renegotiation = renegotiations.joins(:buyer)
                                        .where(users: { company_name: user.company_name })
                                        .order(created_at: :desc)
                                        .first
    
    if latest_renegotiation
      case latest_renegotiation.status
      when "Ongoing"
        "Ongoing"  # User can continue renegotiation
      when "Human_Required"
        "Human_Required"  # Needs human intervention
      when "Done"
        # If last renegotiation is done, check if new one is allowed
        return renegotiation_allowed?(user) ? "Available" : "Pending_Review"
      else
        "Ongoing"  # Default for unknown statuses
      end
    elsif renegotiation_allowed?(user)
      "Available"  # User can start new renegotiation
    elsif contract_expiring_soon?
      "Blocked"  # Contract expiring but user can't act (other company negotiating)
    else
      "Pending_Review"  # Contract not in 6-month window yet
    end
  end

  # CSS-friendly version of display status (lowercase with underscores)
  def display_status_css_class(user)
    display_status_for_user(user).downcase
  end
end
