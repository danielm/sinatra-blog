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
    
    create_table :messages do |t|
      t.string :name, :null => false
      t.string :email, :null => false
      t.text :body
      t.boolean :read, :default => false
      t.timestamps
    end
    
    create_table :taggings do |t|
      t.integer :post_id
      t.integer :tag_id
    end
    
    create_table :tags do |t|
      t.string :name, :null => false
      t.string :slug, :null => false
    end
    
    add_index :tags, :slug, :unique => true
  end
end
