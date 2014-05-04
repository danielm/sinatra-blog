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

get "/acerca.html" do
  @title = "Acerca"
  erb :"pages/acerca"
end

get "/contactar.html" do
  @title = "Contactar"
  erb :"pages/contactar"
end

get "/:page?/?" do
  @page = params[:page] || -1
  if @page == -1
    @page = 0
  elsif @page.to_i <= 1
    redirect to('/'), 301
  else
    @page = @page.to_i - 1
  end

  per_page = 1

  @count = Post.count

  @pages = @count / per_page

  @posts = Post.order("created_at DESC").limit(1).offset(@page * 1)

  if @posts.length == 0
    halt(404)
  end

  @title = "Bienvenido"
  erb :"posts/index"
end

get "/posts/:id/:slug.html" do
  @post = Post.find_by(id: params[:id], slug: params[:slug])

  if @post.nil?
    halt(404)
  end

  @title = @post.title
  erb :"posts/view"
end

get "/error/not_found.html" do
  @title = "Not Found"
  erb :"pages/not_found"
end

get "/error/application.html" do
  @title = "Application Error"
  erb :"pages/application"
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

not_found do
  redirect to('/error/not_found.html')
end

error do
  #'Sorry there was a nasty error - ' + env['sinatra.error'].name
  redirect to('/error/application.html')
end
