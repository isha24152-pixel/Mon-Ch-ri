class CreateNanas < ActiveRecord::Migration[7.2]
  def change
    create_table :nanas do |t|
      t.string :name
      t.string :profile_image

      t.timestamps
    end
  end
end
