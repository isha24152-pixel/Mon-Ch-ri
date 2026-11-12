class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable

  has_many :nanas, dependent: :destroy

  validates :email, presence: true, uniqueness: true

  before_validation :set_default_password, on: :create

  private

  def set_default_password
    self.password = SecureRandom.hex(10) if password.blank?
  end
end
