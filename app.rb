require "rack-flash"
require "pp"

class App < Sinatra::Base
  enable :sessions
  use Rack::Flash

  before do
    if session[:user_id]
      @current_user = User.get() { {where: [{what: "id", is: session[:user_id]}]} }
      @current_user = @current_user[0]
      @subs = Sub.get() { {where: [{what: "subscribed", is: "true", table: "user_memberships"}], join: [{condition: !session[:user_id].nil?, name: "user_memberships", on: [["user_id", {name: session[:user_id], table: false}], ["sub_name", {name: "name", table: true}]], only: "none"}]} }
    else
      @subs = Sub.get()
    end
  end

  get "/" do
    if @current_user
      @posts = Post.get() { {where: [{what: "user_id", is: @current_user.id, table: "user_memberships"}, {what: "subscribed", is: "true", table: "user_memberships"}], join: [{condition: true, name: "subs", on: [["name", {name: "sub_name", table: true}]], only: "none"}, {condition: true, name: "user_memberships", on: [["sub_name", {name: "sub_name", table: true}]], only: "none"}, {condition: true, type: "LEFT", name: "user_upvotes", on: [["post_uuid", {name: "uuid", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["post_uuid"]}, {condition: true, type: "LEFT", name: "user_downvotes", on: [["post_uuid", {name: "uuid", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["post_uuid"]}], order: {type: "dateTime", what: "timestamp", order: "DESC"}} }
      @sublist = Sub.get() { {join: [{condition: true, type: "LEFT", name: "user_memberships", on: [["sub_name", {name: "name", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: "none"}]} }
    else
      @posts = Post.get() { {join: [{condition: true, name: "subs", on: [["name", {name: "sub_name", table: true}]]}], order: {type: "dateTime", what: "timestamp", order: "DESC"}} }
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
    errors = {}
    result = User.login({username: params["username"], password: params["pwd"]})
    if result[:loggedin]
      session[:user_id] = result[:user][0]
      @current_user = result[:user]
      flash[:success] = "Login successful"
    else
      if result[:error] == "username"
        errors[:username] = "Incorrect username!"
      else
        errors[:pwd] = "Incorrect password!"
      end
      flash[:error] = errors
    end
    redirect back
  end

  post "/logout" do
    session.destroy
    flash[:success] = "Logout successful!"
    redirect back
  end

  get "/l/new" do
    if @current_user
      slim :'sub/new'
    else
      redirect back
    end
  end

  get "/l/:name" do
    name = params["name"]
    if @current_user
      mod = Sub.check_mod({user_id: @current_user.id, sub_name: params["name"]})
      mod ? @current_user.mod = true : @current_user.mod = false
    end
    @sub = Sub.get() { {where: [{what: "name", is: name}], join: [{type: "LEFT", condition: !session[:user_id].nil?, name: "user_memberships", on: [["sub_name", {name: "name", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["subscribed", "mod"]}]} }
    @mods = User.get() { {where: [{table: "user_memberships", what: "sub_name", is: name}, {table: "user_memberships", what: "mod", is: "true"}], join: [{condition: true, name: "user_memberships", on: [["user_id", {name: "id", table: true}]]}]} }
    @posts = Post.get() { {where: [{what: "sub_name", is: name}], join: [{condition: true, name: "subs", on: [["name", {name: "sub_name", table: true}]], only: "none"}, {condition: true, type: "LEFT", name: "user_upvotes", on: [["post_uuid", {name: "uuid", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["post_uuid"]}, {condition: true, type: "LEFT", name: "user_downvotes", on: [["post_uuid", {name: "uuid", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["post_uuid"]}], order: {type: "dateTime", what: "timestamp", order: "DESC"}} }
    slim :'sub/index'
  end

  get "/l/:name/post/new" do
    if @current_user
      @name = params["name"]
      slim :'post/new'
    else
      redirect back
    end
  end

  get "/l/:name/settings" do
    if params["search"]
      @result = User.get() { {where: [{what: "username", like: "%" + params["search"] + "%"}]} }
    end
    @path = request.path_info
    slim :"sub/settings"
  end

  post "/l/:name/settings/addmod" do
    Sub.add_mod({sub_name: params["name"], user_id: params["modsel"]})
    redirect "/l/#{params["name"]}"
  end

  post "/l/:name/post/new" do
    Post.new_post({title: params["title"], textbody: params["textbody"], sub_name: params["name"], user: @current_user})
    redirect "/l/#{params["name"]}"
  end

  get "/l/:name/:uuid" do
    @post = Post.get() { {where: [{what: "sub_name", is: params["name"]}, {what: "uuid", is: params["uuid"]}], join: [{condition: true, name: "subs", on: [["name", {name: "sub_name", table: true}]], only: "none"}, {condition: true, type: "LEFT", name: "user_upvotes", on: [["post_uuid", {name: "uuid", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["post_uuid"]}, {condition: true, type: "LEFT", name: "user_downvotes", on: [["post_uuid", {name: "uuid", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["post_uuid"]}], order: {type: "dateTime", what: "timestamp", order: "DESC"}} }
    if @current_user
      mod = Sub.check_mod({user_id: @current_user.id, sub_name: params["name"]})
      mod ? @current_user.mod = true : @current_user.mod = false
    end
    @comments = Comment.get() { {where: [{what: "post_uuid", is: params["uuid"]}], join: [{condition: session[:user_id], type: "LEFT", name: "user_comment_upvotes", on: [["comment_id", {name: "id", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["comment_id"]}, {condition: session[:user_id], type: "LEFT", name: "user_comment_downvotes", on: [["comment_id", {name: "id", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["comment_id"]}], order: {type: "dateTime", what: "timestamp", order: "DESC"}} }
    @post = @post.first
    slim :"post/index"
  end

  post "/l/:name/:uuid/delete" do
    Post.delete({uuid: params["uuid"]})
    redirect "/l/#{params["name"]}"
  end

  get "/l/:name/:uuid/edit" do
    @post = Post.get() { {where: [{what: "uuid", is: params["uuid"]}]} }
    @post = @post.first
    slim :"post/edit"
  end

  post "/l/:name/:uuid/edit" do
    Post.edit({uuid: params["uuid"], text: params["textbody"]})
    redirect "/l/#{params["name"]}/#{params["uuid"]}"
  end

  post "/l/:uuid/vote" do
    Post.vote({params: params, user: @current_user})
    redirect back
  end

  post "/l/new" do
    result = Sub.new_sub({name: params["name"], user: @current_user})
    if !result.nil?
      flash[:error] = result
      redirect back
    else
      redirect "/l/#{params["name"]}"
    end
  end

  post "/l/:name/subscribe" do
    Sub.subscribe({name: params["name"], user: @current_user, name: params["name"]})
    redirect back
  end

  post "/l/:name/unsubscribe" do
    Sub.unsubscribe({name: params["name"], user: @current_user, name: params["name"]})
    redirect back
  end

  post "/l/:name/:uuid/newcomment" do
    if params["textbody"].empty?
      flash[:error] = "No comment to post!"
      redirect back
    end
    Comment.new_comment({textbody: params["textbody"], post_uuid: params["uuid"], user: @current_user, sub_name: params["name"]})
    redirect back
  end

  post "/l/:uuid/comment/:comment_id/vote" do
    Comment.vote({params: params, user: @current_user})
    redirect back
  end

  get "/u/:uname" do
    @user = User.get() { {where: [{what: "username", is: params["uname"]}]} }
    @mods = Sub.get() { {where: [{what: "user_id", is: @user.first.id, table: "user_memberships"}, {what: "mod", is: "true", table: "user_memberships"}], join: [{condition: true, name: "user_memberships", on: [["sub_name", {name: "name", table: true}]]}]} }
    @posts = Post.get() { {where: [{what: "author", is: params["uname"], table: "posts"}], join: [{condition: true, name: "subs", on: [["name", {name: "sub_name", table: true}]], only: "none"}, {condition: true, type: "LEFT", name: "user_upvotes", on: [["post_uuid", {name: "uuid", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["post_uuid"]}, {condition: true, type: "LEFT", name: "user_downvotes", on: [["post_uuid", {name: "uuid", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["post_uuid"]}], order: {type: "dateTime", what: "timestamp", order: "DESC"}} }
    @comments = Comment.get() { {where: [{what: "author", is: params["uname"], table: "comments"}], join: [{condition: session[:user_id], type: "LEFT", name: "user_comment_upvotes", on: [["comment_id", {name: "id", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["comment_id"]}, {condition: session[:user_id], type: "LEFT", name: "user_comment_downvotes", on: [["comment_id", {name: "id", table: true}], ["user_id", {name: session[:user_id], table: false}]], only: ["comment_id"]}, {condition: true, name: "posts", on: [["uuid", {name: "post_uuid", table: true}]], only: ["title"]}], order: {type: "dateTime", what: "comments.timestamp", order: "DESC"}} }
    slim :"user/index"
  end

  not_found do
    status 404
    slim :"common/404"
  end
end
