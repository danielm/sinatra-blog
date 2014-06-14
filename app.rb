# encoding: utf-8

require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'

require 'securerandom'
require './environments'
require './model'

enable :sessions

configure do
  # Authentication
  set :session_secret, ENV['SESSION_SECRET'] || '*&(^B234'
  set :user, ENV['ADMIN_USER'] || 'admin'
  set :password, ENV['ADMIN_PASS'] || 'admin'

  # How many posts per page
  set :per_page, ENV['PER_PAGE'] || 1
end

# Feed
get "/feed" do
  content_type 'application/rss+xml', :charset => 'utf-8'
  @posts = Post.where.not({published_on: nil}).order("published_on DESC").limit(settings.per_page)

  erb :"feed", :layout => false 
end

# Admin
get "/admin" do
  protected!

  env['rack.session']['logged_in'] = true;

  redirect '/admin/posts'
end

# Pages
get "/acerca.html" do
  @title = "Acerca"
  erb :"pages/acerca"
end

# Contact Form
get "/contactar.html" do
  @title = "Contactar"
  @message = Message.new
  
  erb :"pages/contactar"
end

post '/contactar.html' do
  @title = "Contactar"
  @message = Message.new(params[:message])

  g2g = valid_csrf? params[:token]
  
  if g2g && @message.save
    redirect "/", :notice => 'Thanks for your message. We\'ll be in touch soon.'
   end

  erb :"pages/contactar"
end

# Homepage (paginated)
get "/" do
  @title = "Inicio"
  
  if params[:page].nil?
    @page = 0
  elsif params[:page].to_i <= 1
    redirect to('/'), 301
  else
    @page = params[:page].to_i - 1
  end

  count = Post.where.not({published_on: nil}).count.to_i
  pages_n = (count / settings.per_page).ceil

  @page_n = @page + 1
  @have_next = ((@page_n + 1) <= pages_n) ? (@page_n + 1) : false
  @have_previous = (@page_n > 1) ? (@page_n - 1) : false

  @posts = Post.where.not({published_on: nil}).order("published_on DESC").limit(settings.per_page).offset(@page * settings.per_page)

  if @posts.length == 0 && @page > 0
    halt(404)
  end

  erb :"posts/index"
end

# Tag (paginated)
get "/tag/:slug/" do
  @title = "Inicio"
  
  @tag = Tag.find_by(slug: params[:slug])

  if @tag.nil?
    halt(404)
  end

  if params[:page].nil?
    @page = 0
  elsif params[:page].to_i <= 1
    redirect to('/'), 301
  else
    @page = params[:page].to_i - 1
  end

  count = @tag.posts.where.not({published_on: nil}).count.to_i
  pages_n = (count / settings.per_page).ceil

  @page_n = @page + 1
  @have_next = ((@page_n + 1) <= pages_n) ? (@page_n + 1) : false
  @have_previous = (@page_n > 1) ? (@page_n - 1) : false

  @posts = @tag.posts.where.not({published_on: nil}).order("published_on DESC").limit(settings.per_page).offset(@page * settings.per_page)

  if @posts.length == 0 && @page > 0
    halt(404)
  end

  erb :"posts/tag"
end

# Read post
get "/post/:year/:month/:day/:slug.html" do
  @post = Post.find_by(slug: params[:slug])

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
get "/admin/posts" do
 protected!
 @title = "Panel"

 @posts = Post.order("published_on DESC")

 erb :"admin/posts/index"
end

# Create Post
get "/admin/posts/create" do
 protected!
 @title = "Create post"

 @post = Post.new

 erb :"admin/posts/create"
end

post "/admin/posts/create" do
 protected!
 @title = "Create post"

 @post = Post.new(params[:post])
 if @post.save
   redirect "/admin/posts", :notice => 'New post created'
 end

 erb :"admin/posts/create"
end

# Edit Post
get "/admin/posts/edit/:id" do
  protected!
  @title = "Edit post"

  @post = Post.find(params[:id])

  erb :"admin/posts/edit"
end

post "/admin/posts/edit/:id" do
  protected!
  @title = "Edit post"

  @post = Post.find(params[:id])
  
  if @post.nil?
    halt(404)
  end

  @post.update(params[:post])
  if @post.save
    redirect "/admin/posts", :notice => 'Post changes saved'
  end

  erb :"admin/posts/edit"
end

# Delete post
get "/admin/posts/delete/:id" do
  protected!
  @post = Post.find(params[:id])

  if @post.nil?
    halt(404)
  end

  if @post.destroy
    redirect "/admin/posts", :notice => 'Post deleted'
  end
end

# Contact Messages
get "/admin/messages" do
 protected!
 @title = "Contact Messsages"

 @messages = Message.order('read ASC').order("created_at DESC")

 erb :"admin/messages/index"
end

# Delete message
get "/admin/messages/delete/:id" do
  protected!
  @message = Message.find(params[:id])

  if @message.nil?
    halt(404)
  end

  if @message.destroy
    redirect "/admin/messages", :notice => 'Message deleted'
  end
end

# Read message
get "/admin/messages/read/:id" do
  protected!
  @title = "Read message"

  @message = Message.find(params[:id])

  if @message.nil?
    halt(404)
  end

  @message.read = true
  @message.save

  erb :"admin/messages/read"
end

# Tags
get "/admin/tags" do
 protected!
 @title = "Tags"

 @tags = Tag.order('name ASC')

 erb :"admin/tags/index"
end

# Delete tags
get "/admin/tags/delete/:id" do
  protected!
  @tag = Tag.find(params[:id])

  if @tag.nil?
    halt(404)
  end

  if @tag.destroy
    redirect "/admin/tags", :notice => 'Tags deleted'
  end
end

helpers do
  include Rack::Utils

  alias_method :h, :escape_html

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

  def logged_in?
    env['rack.session']['logged_in'] == true
  end

  def csrf_token
    token = SecureRandom.base64(32)

    env['rack.session']['csrf_token'] = token

    token
  end 

  def valid_csrf?(token)
    return true if env['rack.session']['csrf_token'] == token
  end

  def current?(path='')
    request.path_info=='/'+path ? 'active':  nil
  end
  
  def link(url='')
    request.base_url + "/" + url
  end

  def tags
    Tag.all.order('name ASC')
  end
end

not_found do
  redirect to('/error/not_found.html')
end

error do
  #'Sorry there was a nasty error - ' + env['sinatra.error'].name
  redirect to('/error/application.html')
end

# Redirect www. to our root domain
before do
  redirect request.url.sub(/www\./, ''), 301 if request.host.start_with?("www.")
end
