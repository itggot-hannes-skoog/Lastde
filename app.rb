#models = Dir.glob('models/*.rb')
#models.each { |model| require_relative model }

require_relative "models/sub"
require_relative "models/post"
require_relative "models/comment"
require_relative "models/user"

class App < Sinatra::Base
  enable :sessions

  before do
    if session[:user_id]
      @current_user = User.get({id: session[:user_id]})
      @subs = Sub.get({type: "header", user: @current_user})
    else
      @subs = Sub.get({type: "header"})
    end
  end

  get "/" do
    if @current_user
      @posts = Post.get({type: "startpage", user: @current_user})
    else
      @posts = Post.get({type: "startpage"})
    end

    slim :'startpage/index'
  end

  get "/register" do
    slim :'user/register'
  end

  post "/register" do
    User.register(params)
    redirect "/"
  end

  post "/login" do
    username = params["username"]
    db = SQLite3::Database.new "database.db"
    user = db.execute("SELECT id, password
                        FROM users
                        WHERE username = ?", username).first
    if user == nil
      @info = "Incorrect username!"
      redirect "/"
    end
    hashed_pwd = BCrypt::Password.new(user[1])
    if hashed_pwd == params["pwd"]
      @info = "Logged in"
      session[:user_id] = user[0]
      @current_user = user
    else
      @info = "Incorrect password!"
    end
    redirect back
  end

  post "/logout" do
    session.destroy
    redirect back
  end

  get "/l/new" do
    slim :'sub/new'
  end

  get "/l/:id" do
    id = params["id"]
    p id
    @sub = Sub.get({type: "sub", id: id, user: @current_user})
    @posts = Post.get({type: "sub", sub_id: id})
    slim :'sub/index'
  end

  get "/l/:id/post/new" do
    @id = params["id"]
    slim :'posts/new'
  end

  post "/l/:id/post/new" do
    Post.new_post(params, @current_user)
    redirect "/l/#{params["id"]}"
  end

  get "/l/:id/post/:uuid" do
    @post = Post.get({type: "post", sub_id: params["id"], uuid: params["uuid"]})
    @comments = Comment.get({type: "post", uuid: params["uuid"]})
    slim :"posts/index"
  end

  post "/l/new" do
    Sub.new_sub(params)
  end

  post "/l/:id/subscribe" do
    user = @current_user
    id = params["id"]
    Sub.subscribe(id, user)
    redirect back
  end

  post "/l/:id/unsubscribe" do
    user = @current_user
    id = params["id"]
    Sub.unsubscribe(id, user)
    redirect back
  end

  post "/l/:id/:uuid/newcomment" do
    p params
    Comment.new_comment(params, @current_user)
    redirect back
  end

  get "/u/:uname" do
    @user = User.get({uname: params["uname"]})
    @posts = Post.get({type: "user", user: params["uname"]})
    @comments = Comment.get({type: "user", user: params["uname"]})
    slim :"user/index"
  end
end
