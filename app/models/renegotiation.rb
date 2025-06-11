class Renegotiation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer,    class_name: "User"
  belongs_to :supplier, class_name: "User"

  validates :tone,       presence: true
  validates :min_target, presence: true
  validates :max_target, presence: true
end
