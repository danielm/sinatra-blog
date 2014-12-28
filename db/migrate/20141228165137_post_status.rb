class PostStatus < ActiveRecord::Migration
  def change
    add_column :posts, :status, :integer, after: :id, default: 1
  end
end
