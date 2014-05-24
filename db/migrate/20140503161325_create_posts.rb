class CreatePosts < ActiveRecord::Migration
  def change
  	create_table :posts do |t|
      t.string :title, :null => false
      t.string :slug, :null => false
      t.datetime :published_on
      t.text :body
      t.timestamps
    end

    add_index :posts, :slug, :unique => true
  end
end
