require_relative "models/sub"
require_relative "models/posts"
require_relative "models/common"
require_relative "models/users"

class App < Sinatra::Base
  enable :sessions

  get "/" do
    if session[:user_id]
      @current_user = Users.get(session[:user_id])
      @posts = Posts.startpage_get(@current_user)
    else
      @posts = Posts.get_all()
    end

    slim :'startpage/index'
  end

  get "/register" do
    slim :'common/register'
  end

  post "/register" do
    Common.register(params)
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
    if session[:user_id]
      @current_user = Users.get(session[:user_id])
    end

    slim :'sub/new'
  end

  get "/l/:id" do
    if session[:user_id]
      @current_user = Users.get(session[:user_id])
    end

    id = params["id"]

    @sub = Sub.get(id, @current_user)
    @posts = Posts.get_sub(id)
    slim :'sub/index'
  end

  get "/l/:id/post/new" do
    if session[:user_id]
      @current_user = Users.get(session[:user_id])
    end

    @id = params["id"]
    slim :'posts/new'
  end

  post "/l/:id/post/new" do
    if session[:user_id]
      @current_user = Users.get(session[:user_id])
    end

    Posts.new_post(params, @current_user)
    redirect "/l/#{params["id"]}"
  end

  get "/l/:id/post/:uuid" do
    if session[:user_id]
      @current_user = Users.get(session[:user_id])
    end

    @post = Posts.get(params)
    slim :"posts/index"
  end

  post "/l/new" do
    Sub.new_sub(params)
  end

  post "/l/:id/subscribe" do
    user = Users.get(session[:user_id])
    id = params["id"]
    Sub.subscribe(id, user)
    redirect back
  end

  post "/l/:id/unsubscribe" do
    user = Users.get(session[:user_id])
    id = params["id"]
    Sub.unsubscribe(id, user)
    redirect back
  end
end
