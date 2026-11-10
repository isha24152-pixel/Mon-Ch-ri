class User < ApplicationRecord
  # :validatable を外すことで、パスワードの必須チェックを解除します
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable

  # Nana（チャットデータ）との紐付け（これが必要でした！）
  has_many :nanas, dependent: :destroy

  # メールアドレスの重複・存在チェックのみ行う
  validates :email, presence: true, uniqueness: true

  # 登録時にパスワードが空なら自動でランダムなパスワードをセットする
  before_validation :set_default_password, on: :create

  private

  def set_default_password
    self.password = SecureRandom.hex(10) if password.blank?
  end
end
