class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Product associations (for suppliers)
  has_many :products, foreign_key: :supplier_id
  # Below for the chatbot
  has_many :questions, dependent: :destroy

  # Renegotiation associations
  has_many :buyer_renegotiations, class_name: 'Renegotiation', foreign_key: :buyer_id
  has_many :supplier_renegotiations, class_name: 'Renegotiation', foreign_key: :supplier_id
  has_many :supplied_products, class_name: "Product", foreign_key: "supplier_id"

  # DISCOUNT TARGET ASSOCIATIONS
  has_many :discount_target_histories, foreign_key: :set_by_user_id, dependent: :nullify

  validates :company_name, presence: true
  validates :role, presence: true
  validates :contact, presence: true
end
