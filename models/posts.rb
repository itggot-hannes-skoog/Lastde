class Posts
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

  def self.startpage_get(user)
    db = SQLite3::Database.new "database.db"
    subs = db.execute("SELECT sub_id
                        FROM user_subs
                        WHERE user_id = ?",
                      user.id)
    posts = []
    subs.each_with_index do |id|
      posts += db.execute("SELECT posts.*, subs.name 
                            AS sub_name from posts 
                            JOIN subs 
                            ON posts.sub_id = subs.ID 
                            WHERE sub_id = ?",
                          id)
    end
    posts.map { |post| Posts.new(post) }
  end

  def self.get(data)
    id = data["id"]
    uuid = data["uuid"]
    db = SQLite3::Database.new "database.db"
    post = db.execute("SELECT *
                        FROM posts
                        WHERE sub_id = ?
                        AND uuid = ?",
                      id, uuid).first
    Posts.new(post)
  end

  def self.get_sub(id)
    db = SQLite3::Database.new "database.db"
    posts = db.execute("SELECT posts.*, subs.name 
                            AS sub_name from posts 
                            JOIN subs 
                            ON posts.sub_id = subs.ID 
                            WHERE sub_id = ?",
                       id)
    posts.map { |post| Posts.new(post) }
  end

  def self.get_all()
    db = SQLite3::Database.new "database.db"
    posts = db.execute("SELECT posts.*, subs.name
                        AS sub_name from posts 
                        JOIN subs 
                        ON posts.sub_id = subs.ID
                        ORDER BY dateTime(timestamp)
                        DESC")
    posts.map { |post| Posts.new(post) }
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
