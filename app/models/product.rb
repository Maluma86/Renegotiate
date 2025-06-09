class Product < ApplicationRecord
  belongs_to :supplier, class_name: 'User'
  has_many :renegotiations

  validates :name, presence: true
  validates :category, presence: true
  validates :description, presence: true
  validates :current_price, presence: true
  validates :contract_end_date, presence: true
end
