class Product < ApplicationRecord
  belongs_to :supplier, class_name: 'User' # this means “Treat supplier_id as a foreign key to the users table — and treat the related record as a User.”
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

  def last_month_volume
    read_attribute(:last_month_volume) || 0
  end

  def last_year_volume
    last_month_volume.to_f * 12
  end

  # WHAT IT IS : below is the function to automatically update the status.
    # So when you upload it it is pending = no renegotiation started
    # then when the user clicks on renegotiation and a negotiation starts, it is "ongoing"
    # if a user clicked on talk to a human it is "human required"
    # when it is done it is "done"
  def renegotiation_status(current_user)
    # selects the right renegotiations for the product
    latest = renegotiations
      .where(buyer_id: current_user.id)
      .order(created_at: :desc)
      .first

    # If the product has no renegotiations (renegotiations.none?), we immediately return "pending".
    return "pending" if latest.nil?

    case latest.status.to_s.downcase  # We now look at the status of that latest renegotiation
    when "escalated"
      "escalated"
    when "ongoing", "initialized"    # If it’s initialized/in progress, treat as ongoing.
      "ongoing"
    when "done"                      # If the renegotiation is marked done, return done.
      "done"
    else
      "pending"
    end
  end
end
