class Post
  attr_reader :id, :title, :textbody, :timestamp, :sub_id, :uuid, :sub_name, :author

  def initialize(data)
    @id = data[0]
    @title = data[1]
    @textbody = data[2]
    @timestamp = data[3]
    @img = data[4]
    @sub_id = data[5]
    @uuid = data[6]
    @author = data[7]
    @sub_name = data[8]
  end

  def self.get(data)
    db = SQLite3::Database.new "database.db"
    if data[:type] == "startpage"
      if data[:user]
        user = data[:user]
        posts = db.execute("SELECT posts.*, subs.name AS sub_name, user_subs.*
                            FROM posts
                            JOIN subs ON posts.sub_id = subs.ID
                            JOIN user_subs ON posts.sub_id = user_subs.sub_id
                            WHERE user_subs.user_id = ?
                            ORDER BY dateTime(timestamp)
                            DESC",
                           user.id)
      else
        posts = db.execute("SELECT posts.*, subs.name
                            AS sub_name
                            FROM posts 
                            JOIN subs 
                            ON posts.sub_id = subs.ID
                            ORDER BY dateTime(timestamp)
                            DESC")
      end
    elsif data[:type] == "sub"
      id = data[:sub_id]
      posts = db.execute("SELECT posts.*, subs.name 
                          AS sub_name 
                          FROM posts 
                          JOIN subs 
                          ON posts.sub_id = subs.ID 
                          WHERE sub_id = ?
                          ORDER BY dateTime(timestamp)
                          DESC",
                         id)
    elsif data[:type] == "user"
      uname = data[:user]
      posts = db.execute("SELECT *
                            FROM posts
                            WHERE posts.author = ?
                            ORDER BY dateTime(timestamp)
                            DESC",
                         uname)
    elsif data[:type] == "post"
      id = data[:sub_id]
      uuid = data[:uuid]
      post = db.execute("SELECT posts.*, subs.name 
                          AS sub_name
                          FROM posts 
                          JOIN subs 
                          ON posts.sub_id = subs.ID 
                          WHERE sub_id = ?
                          AND uuid = ?",
                        id, uuid).first
      return Post.new(post)
    end
    posts.map { |post| Post.new(post) }
  end

  def self.new_post(data, user)
    title = data["title"]
    textbody = data["textbody"]
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
    uuid = SecureRandom.urlsafe_base64(8, false)
    img = ""
    sub_id = data["id"]
    author = user.uname
    db = SQLite3::Database.new "database.db"
    db.execute("INSERT INTO posts
                (title, textbody, timestamp, sub_id, uuid, author)
                VALUES (?, ?, ?, ?, ?, ?)
                ", [title, textbody, timestamp, sub_id, uuid, author])
  end
end
