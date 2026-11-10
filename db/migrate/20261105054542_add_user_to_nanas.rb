class AddUserToNanas < ActiveRecord::Migration[7.0]
def change
  # null: false を取り除き、NULLを許可する設定に変更します
  add_reference :nanas, :user, foreign_key: true
end
end