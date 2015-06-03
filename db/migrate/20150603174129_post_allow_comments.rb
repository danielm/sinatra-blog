class PostAllowComments < ActiveRecord::Migration
  def change
    add_column :posts, :allow_comments, :boolean, after: :status, default: true
  end
end
