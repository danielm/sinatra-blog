# encoding: utf-8

require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'sinatra/js'
require 'sinatra/r18n'

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
  set :per_page, ENV['PER_PAGE'].nil? ? 1 : ENV['PER_PAGE'].to_i
  
  # Blog settings
  set :blog_name, ENV['BLOG_NAME'] || 'Sinatra Blog CMS'
  set :blog_description, ENV['BLOG_DESCRIPTION'] || 'Simple Blog CMS using SinatraRB'
  set :disqus_id, ENV['DISQUS_ID'] || false
  set :analytics_id, ENV['ANALYTICS_ID'] || false
  set :date_format, ENV['DATE_FORMAT'] || '%Y-%m-%d %I:%M%p'
  
  set :author_name, ENV['AUTHOR_NAME'] || 'Jon Doe'
  set :author_link, ENV['AUTHOR_LINK'] || 'http://github.com/danielm/sinatra-blog'
end

# Feed
get "/feed" do
  content_type 'application/rss+xml', :charset => 'utf-8'
  @posts = Post.where('status = ? AND published_on <= ?', 1, Time.now).order("published_on DESC").limit(settings.per_page)

  erb :"feed", :layout => false 
end

# Pages
get "/p/:slug.html" do
  @page = Page.find_by(slug: params[:slug])

  if @page.nil?
    halt(404)
  end

  @title = @page.title
  erb :"pages/page"
end

# Wiki
get "/wiki/:name/?:section?" do
  if params[:name].nil?
    halt(404)
  end
  
  tpl = params[:section] || "index"

  @title = params[:name].titleize
  @hide_sidebar = true
  erb :"wiki/#{params[:name]}/#{tpl}"
end

# Contact Form
get "/contact" do
  @title = t.contact.title
  @message = Message.new
  
  erb :"pages/contact"
end

post '/contact' do
  @title = t.contact.title
  @message = Message.new(params[:message])

  g2g = valid_csrf? params[:token]
  
  if g2g && @message.save
    redirect "/", :notice => t.contact.sent
   end

  erb :"pages/contact"
end

# Homepage (paginated)
get "/" do
  @title = t.home.title
  
  if params[:page].nil?
    @page = 0
  elsif params[:page].to_i <= 1
    redirect to('/'), 301
  else
    @page = params[:page].to_i - 1
  end

  count = Post.where.not({published_on: nil}).count.to_f
  pages_n = (count / settings.per_page).ceil

  @page_n = @page + 1
  @have_next = ((@page_n + 1) <= pages_n) ? (@page_n + 1) : false
  @have_previous = (@page_n > 1) ? (@page_n - 1) : false

  @posts = Post.where('status = ? AND published_on <= ?', 1, Time.now).order("published_on DESC").limit(settings.per_page).offset(@page * settings.per_page)

  if @posts.length == 0 && @page > 0
    halt(404)
  end

  erb :"posts/index"
end

# Tag (paginated)
get "/tag/:slug/" do  
  @tag = Tag.find_by(slug: params[:slug])

  if @tag.nil?
    halt(404)
  end
  
  @title = t.home.tag(@tag.name)

  if params[:page].nil?
    @page = 0
  elsif params[:page].to_i <= 1
    redirect to('/'), 301
  else
    @page = params[:page].to_i - 1
  end

  count = @tag.posts.where.not({published_on: nil}).count.to_f
  pages_n = (count / settings.per_page).ceil

  @page_n = @page + 1
  @have_next = ((@page_n + 1) <= pages_n) ? (@page_n + 1) : false
  @have_previous = (@page_n > 1) ? (@page_n - 1) : false

  @posts = @tag.posts.where('status = ? AND published_on <= ?', 1, Time.now).order("published_on DESC").limit(settings.per_page).offset(@page * settings.per_page)

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
  @title = t.error.not_found
  erb :"pages/not_found"
end

get "/error/application.html" do
  @title = t.error.application_error
  erb :"pages/application"
end

# Filters
before '/admin/*' do
  protected!
  
  env['rack.session']['logged_in'] = true;
  
  @hide_sidebar = true
end

# Administration Dashboard
get "/admin" do
  redirect '/admin/post'
end

#
# Simple CURD for our admin panel
#

# List
get "/admin/:module" do
 model_name = params[:module].capitalize
 model_class = Module.const_get(model_name)
 
 @title = t.panel.crud.title(model_name)
 @entities = model_class.order("id DESC")
 
 erb :"admin/#{params[:module]}/index"
end

# Create
get "/admin/:module/create" do
 model_name = params[:module].capitalize
 model_class = Module.const_get(model_name)
 
 @title = t.panel.crud.create(model_name)

 @entity = model_class.new

 erb :"admin/#{params[:module]}/create"
end

post "/admin/:module/create" do
 model_name = params[:module].capitalize
 model_class = Module.const_get(model_name)
 
 @title = t.panel.crud.create(model_name)
 @entity = model_class.new(params[:entity])
 
 if @entity.save
   redirect "/admin/#{params[:module]}", :notice => t.panel.crud.created(model_name)
 end

 erb :"admin/#{params[:module]}/create"
end

# Edit
get "/admin/:module/edit/:id" do
  model_name = params[:module].capitalize
  model_class = Module.const_get(model_name)

  @entity = model_class.find(params[:id])
  @title = t.panel.crud.edit(model_name, @entity.id)
  
  if @entity.nil?
    halt(404)
  end

  erb :"admin/#{params[:module]}/edit"
end

post "/admin/:module/edit/:id" do
  model_name = params[:module].capitalize
  model_class = Module.const_get(model_name)
  
  @entity = model_class.find(params[:id])
  @title = t.panel.crud.edit(model_name, @entity.id)
  
  if @entity.nil?
    halt(404)
  end

  @entity.update(params[:entity])
  if @entity.save
    redirect "/admin/#{params[:module]}", :notice => t.panel.crud.edited(model_class, @entity.id)
  end

  erb :"admin/#{params[:module]}/edit"
end

# Delete
get "/admin/:module/delete/:id" do
  model_name = params[:module].capitalize
  model_class = Module.const_get(model_name)
  
  @entity = model_class.find(params[:id])

  if @entity.nil?
    halt(404)
  end

  if @entity.destroy
    redirect "/admin/#{params[:module]}", :notice => t.panel.crud.deleted(model_class, @entity.id)
  end
end

# Read message
get "/admin/message/read/:id" do
  @message = Message.find(params[:id])
  
  @title = t.panel.message.read(@message.id)

  if @message.nil?
    halt(404)
  end

  @message.read = true
  @message.save

  erb :"admin/message/read"
end

helpers do
  include Rack::Utils

  alias_method :h, :escape_html

  def menu
    Page.all.order('title ASC')
  end

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
  
  def sidebar?
    @hide_sidebar.nil? || @hide_sidebar == false
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
