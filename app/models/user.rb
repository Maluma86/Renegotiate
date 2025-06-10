class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # Product associations (for suppliers)
  has_many :products, foreign_key: :supplier_id
  
  # Renegotiation associations
  has_many :buyer_renegotiations, class_name: 'Renegotiation', foreign_key: :buyer_id
  has_many :supplier_renegotiations, class_name: 'Renegotiation', foreign_key: :supplier_id

  validates :company_name, presence: true
  validates :role, presence: true
  validates :contact, presence: true
  validates :contact_email, presence: true
end
