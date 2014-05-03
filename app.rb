# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require './environments'


class Post < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 5, maximum: 255  }
  validates :slug, uniqueness: { case_sensitive: false }
  validates :body, presence: true

  before_save :create_slug

  def create_slug
    self.slug = self.title.parameterize
  end
end

get "/" do
  @posts = Post.order("created_at DESC")
  @title = "Welcome."
  erb :"posts/index"
end

get "/posts/:id/:slug.html" do
  @post = Post.find_by(id: params[:id], slug: params[:slug])
  @title = @post.title
  erb :"posts/view"
end

helpers do
  def title
    if @title
      "#{@title}"
    else
      "Welcome."
    end
  end
end
