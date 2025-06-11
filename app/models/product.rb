class Product < ApplicationRecord
  belongs_to :supplier, class_name: 'User' #this means “Treat supplier_id as a foreign key to the users table — and treat the related record as a User.”
  belongs_to :procurement, class_name: 'User'


  has_many :renegotiations

  validates :name, presence: true
  validates :category, presence: true
  validates :description, presence: true
  validates :current_price, presence: true
  validates :contract_end_date, presence: true
end
