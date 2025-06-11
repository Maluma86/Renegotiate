class Product < ApplicationRecord
  belongs_to :supplier, class_name: 'User' #this means “Treat supplier_id as a foreign key to the users table — and treat the related record as a User.”
  belongs_to :procurement, class_name: 'User'


  has_many :renegotiations

  validates :name, presence: true
  validates :category, presence: true
  validates :description, presence: true
  validates :current_price, presence: true
  validates :contract_end_date, presence: true
  # …
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
end
