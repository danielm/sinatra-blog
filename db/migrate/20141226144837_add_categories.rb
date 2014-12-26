class AddCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name, :null => false
      t.string :slug, :null => false
    end
  
    add_column :posts, :category_id, :integer, after: :id, null: true
  end
end
