class AddAiToNanas < ActiveRecord::Migration[7.2]
  def change
    add_column :nanas, :ai_question, :text
    add_column :nanas, :ai_response, :text
  end
end
