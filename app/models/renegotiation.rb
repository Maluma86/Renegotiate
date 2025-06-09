class Renegotiation < ApplicationRecord
  has_one :product

  validates :tone, presence: true
  validates :min_target, presence: true
  validates :max_target, presence: true
end
