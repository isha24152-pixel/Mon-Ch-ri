class AddUserToNanas < ActiveRecord::Migration[7.0]
  def change
    # null: false を外すことで、DB構築時のエラーを回避します
    add_reference :nanas, :user, foreign_key: true
  end
end
