# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require './environments'

enable :sessions

# Authentication
set :session_secret, '*&(^B234'
set :user, 'admin'
set :password, 'admin'

# Post list
set :per_page, 1

# Contact Form
set :email_username, ENV['SENDGRID_USERNAME'] || 'username@gmail.com'
set :email_password, ENV['SENDGRID_PASSWORD'] || 'password'
set :email_address, 'someone@host.com'
set :email_service, ENV['EMAIL_SERVICE'] || 'gmail.com'
set :email_domain, ENV['SENDGRID_DOMAIN'] || 'localhost.localdomain'

# Model
class Post < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 5, maximum: 255  }
  validates :slug, uniqueness: { case_sensitive: false }
  validates :body, presence: true

  before_save :create_slug

  def create_slug
    self.slug = self.title.parameterize
  end
end

# Pages
get "/acerca.html" do
  @title = "Acerca"
  erb :"pages/acerca"
end

get "/contactar.html" do
  @title = "Contactar"
  erb :"pages/contactar"
end

post '/contactar.html' do 
  require 'pony'
  Pony.mail(
    :from => params[:name] + "<" + params[:email] + ">",
    :to => settings.email_address,
    :subject => params[:name] + " has contacted you",
    :body => params[:message],
    :via => :smtp,
    :via_options => { 
      :address              => 'smtp.' + settings.email_service, 
      :port                 => '587', 
      :enable_starttls_auto => true, 
      :user_name            => settings.email_username, 
      :password             => settings.email_password, 
      :authentication       => :plain, 
      :domain               => settings.email_domain
    })
  erb :"pages/contactar_success"
end

# Homepage (paginated)
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

# Read post
get "/posts/:id/:slug.html" do
  @post = Post.find_by(id: params[:id], slug: params[:slug])

  if @post.nil?
    halt(404)
  end

  @title = @post.title
  erb :"posts/view"
end

# Error messages
get "/error/not_found.html" do
  @title = "Not Found"
  erb :"pages/not_found"
end

get "/error/application.html" do
  @title = "Application Error"
  erb :"pages/application"
end

# Administration
get "/admin/create" do
 protected!
 @title = "Create post"

 erb :"admin/create"
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
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [settings.user, settings.password]
  end
end

not_found do
  redirect to('/error/not_found.html')
end

error do
  #'Sorry there was a nasty error - ' + env['sinatra.error'].name
  redirect to('/error/application.html')
end
