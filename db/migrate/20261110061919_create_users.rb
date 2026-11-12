class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    unless table_exists?(:users)
      create_table :users do |t|
        t.string :email, default: "", null: false
        t.string :encrypted_password, default: "", null: false
        t.string :reset_password_token
        t.datetime :reset_password_sent_at
        t.datetime :remember_created_at
        t.timestamps
      end
    end

    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)

    unless column_exists?(:nanas, :user_id)
      add_reference :nanas, :user, foreign_key: true
    end

    unless foreign_key_exists?(:nanas, :users)
      add_foreign_key :nanas, :users
    end
  end
end
