class Post < Model
  attr_reader :id, :title, :textbody, :timestamp, :sub_id, :uuid, :sub_name, :author, :upvotes, :downvotes, :comments, :upvoted, :downvoted

  table_name "posts"

  def initialize(data)
    @id = data[0]
    @title = data[1]
    @textbody = data[2]
    @timestamp = data[3]
    @sub_name = data[4]
    @uuid = data[5]
    @author = data[6]
    @upvotes = data[7]
    @downvotes = data[8]
    @comments = data[9]
    @upvoted = data[10]
    @downvoted = data[11]
  end

  def self.new_post(data)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
    uuid = SecureRandom.urlsafe_base64(8, false)
    img = ""
    user = data[:user]
    name = data[:sub_name]
    db = SQLite3::Database.new "database.db"
    db.execute("INSERT INTO posts
                (title, textbody, timestamp, sub_name, uuid, author, upvotes, downvotes, comments)
                VALUES (?, ?, ?, ?, ?, ?, 1, 0, 0)
                ", [data[:title], data[:textbody], timestamp, name, uuid, user.uname])
    db.execute("INSERT INTO user_upvotes
                (user_id, post_uuid)
                VALUES (?, ?)
              ", user.id, uuid)
  end

  def self.vote(data)
    uuid = data[:params]["uuid"]
    user = data[:user]
    db = SQLite3::Database.new "database.db"
    if data[:params]["upvote"]
      db.execute("UPDATE posts
                    SET upvotes = upvotes + 1
                    WHERE uuid = ?
                  ", uuid)
      db.execute("INSERT INTO user_upvotes
                    (user_id, post_uuid)
                    VALUES (?, ?)
                  ", user.id, uuid)
    elsif data[:params]["downvote"]
      db.execute("UPDATE posts
                    SET downvotes = downvotes + 1
                    WHERE uuid = ?
                  ", uuid)
      db.execute("INSERT INTO user_downvotes
                  (user_id, post_uuid)
                  VALUES (?, ?)
                  ", user.id, uuid)
    elsif data[:params]["removeupvote"]
      db.execute("UPDATE posts
                    SET upvotes = upvotes - 1
                    WHERE uuid = ?
                  ", uuid)
      db.execute("DELETE
                  FROM user_upvotes
                  WHERE post_uuid = ?
                  ", uuid)
    elsif data[:params]["removedownvote"]
      db.execute("UPDATE posts
                  SET downvotes = downvotes - 1
                  WHERE uuid = ?
                ", uuid)
      db.execute("DELETE 
                  FROM user_downvotes
                  WHERE post_uuid = ?
                  ", uuid)
    end
  end

  def self.edit(data)
    db = SQLite3::Database.new "database.db"
    db.execute("UPDATE posts
                SET textbody = ?
                WHERE uuid = ?
                ", data[:text], data[:uuid])
  end

  def self.delete(data)
    db = SQLite3::Database.new "database.db"
    db.execute("DELETE FROM posts
                WHERE uuid = ?
                ", data[:uuid])
    db.execute("DELETE FROM comments
                WHERE sub_name = ?
                ", data[:name])
  end
end
