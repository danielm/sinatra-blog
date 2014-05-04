# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require './environments'

enable :sessions

set :per_page, 1

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
  if params[:page].nil?
    @page = 0
  elsif params[:page].to_i <= 1
    redirect to('/'), 301
  else
    @page = params[:page].to_i - 1
  end

  count = Post.count.to_f
  pages_n = (count / settings.per_page).ceil

  @page_n = @page + 1
  @have_next = ((@page_n + 1) <= pages_n) ? (@page_n + 1) : false
  @have_previous = (@page_n > 1) ? (@page_n - 1) : false

  @posts = Post.order("created_at DESC").limit(settings.per_page).offset(@page * settings.per_page)

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

# Admin
get "/admin" do
 protected!

 redirect to('/')
end


helpers do
  include Rack::Utils

  def title
    if @title
      "#{@title}"
    else
      "Welcome."
    end
  end

  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'admin']
  end
end

not_found do
  redirect to('/error/not_found.html')
end

error do
  #'Sorry there was a nasty error - ' + env['sinatra.error'].name
  redirect to('/error/application.html')
end
