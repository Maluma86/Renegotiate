<<<<<<< HEAD
# class Renegotiation < ApplicationRecord
#   has_one :product
=======
class Renegotiation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer, class_name: 'User'
  belongs_to :supplier, class_name: 'User'
>>>>>>> 45ec7ffed3dadd3fad9c7d5a0b8b64435146f424

#   validates :tone, presence: true
#   validates :min_target, presence: true
#   validates :max_target, presence: true
# end
class Renegotiation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer,    class_name: "User"
  belongs_to :supplier, class_name: "User"

  validates :tone,       presence: true
  validates :min_target, presence: true
  validates :max_target, presence: true
end
