#models = Dir.glob('models/*.rb')
#models.each { |model| require_relative model }

require_relative "models/sub"
require_relative "models/post"
require_relative "models/comment"
require_relative "models/user"

class App < Sinatra::Base
  enable :sessions
  register Sinatra::Flash

  before do
    if session[:user_id]
      @current_user = User.get({type: "session", id: session[:user_id]})
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
    result = User.login({username: params["username"], password: params["pwd"]})
    session[:user_id] = result[:user][0]
    @current_user = result[:user]
    flash[:success] = "Registration successful!"
    redirect "/"
  end

  post "/login" do
    result = User.login({username: params["username"], password: params["pwd"]})
    if result[:loggedin]
      session[:user_id] = result[:user][0]
      @current_user = result[:user]
      flash[:success] = "Login successful!"
    else
      flash[:error] = "Incorrect login credentials!"
    end
    redirect back
  end

  post "/logout" do
    session.destroy
    flash[:success] = "Logout successful!"
    redirect back
  end

  get "/l/new" do
    slim :'sub/new'
  end

  get "/l/:name" do
    name = params["name"]
    @sub = Sub.get({type: "sub", name: name, user: @current_user})
    @posts = Post.get({type: "sub", sub_name: name, user: @current_user})
    slim :'sub/index'
  end

  get "/l/:name/post/new" do
    @name = params["name"]
    slim :'posts/new'
  end

  post "/l/:name/post/new" do
    Post.new_post({title: params["title"], textbody: params["textbody"], sub_name: params["name"], user: @current_user})
    redirect "/l/#{params["name"]}"
  end

  get "/l/:name/:uuid" do
    @post = Post.get({type: "post", user: @current_user, sub_name: params["name"], uuid: params["uuid"]})
    @comments = Comment.get({type: "post", uuid: params["uuid"]})
    @post = @post.first
    slim :"posts/index"
  end

  post "/l/:uuid/vote" do
    if params["upvote"]
      vote = "upvote"
    elsif params["downvote"]
      vote = "downvote"
    elsif params["removeupvote"]
      vote = "removeupvote"
    elsif params["removedownvote"]
      vote = "removedownvote"
    end
    Post.vote({type: vote, uuid: params["uuid"], user: @current_user})
    redirect back
  end

  post "/l/new" do
    chars = ("a".."z").to_a + ("A".."Z").to_a + (0..9).to_a + ["-", "_"]
    p params["name"]
    if !params["name"].chars.detect { |ch| !chars.include?(ch) }.nil?
      flash[:error] = "Illegal subname, non alphanumeric characters!"
      redirect back
    elsif params["name"].size > 20
      flash[:error] = "Illegal subname, too long!"
      redirect back
    else
      Sub.new_sub({name: params["name"]})
      redirect "/l/1"
    end
  end

  post "/l/:name/subscribe" do
    Sub.subscribe({name: params["name"], user: @current_user})
    redirect back
  end

  post "/l/:name/unsubscribe" do
    Sub.unsubscribe({name: params["name"], user: @current_user})
    redirect back
  end

  post "/l/:name/:uuid/newcomment" do
    Comment.new_comment({textbody: params["textbody"], post_uuid: params["uuid"], user: @current_user})
    redirect back
  end

  post "/l/:uuid/comment/:comment_id/vote" do
    vote = params["upvote"] ? "upvote" : "downvote"
    Comment.vote({type: vote, user: @current_user, comment_id: params["comment_id"]})
    redirect back
  end

  get "/u/:uname" do
    @user = User.get({type: "userpage", username: params["uname"]})
    @posts = Post.get({type: "user", username: params["uname"]})
    @comments = Comment.get({type: "user", username: params["uname"]})
    slim :"user/index"
  end
end
