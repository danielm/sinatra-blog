class PageStatus < ActiveRecord::Migration
  def change
    add_column :pages, :status, :integer, after: :id, default: 1
  end
end
