class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :products
  has_many :renegotiations, through: :products

  validates :company_name, presence: true
  validates :role, presence: true
  validates :contact, presence: true
  validates :contact_email, presence: true
end
