class Comment < Model
  attr_reader :id, :textbody, :timestamp, :uuid, :author, :upvotes, :downvotes, :sub_id, :upvoted, :downvoted, :post_title, :sub_name

  table_name "comments"

  def initialize(data)
    @id = data[0]
    @textbody = data[1]
    @timestamp = data[2]
    @uuid = data[3]
    @author = data[4]
    @upvotes = data[5]
    @downvotes = data[6]
    @sub_name = data[7]
    @upvoted = data[8]
    @downvoted = data[9]
    @post_title = data[10]
  end

  def self.new_comment(data)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
    author = data[:user].uname
    db = SQLite3::Database.new "database.db"
    db.execute("INSERT INTO comments
                    (textbody, timestamp, post_uuid, author, upvotes, downvotes, sub_name)
                    VALUES (?, ?, ?, ?, 1, 0, ?)
                    ", [data[:textbody], timestamp, data[:post_uuid], author, data[:sub_name]])
    comment_id = db.execute("SELECT last_insert_rowid()")
    db.execute("INSERT INTO user_comment_upvotes
                (user_id, comment_id)
                VALUES (?, ?)", [data[:user].id, comment_id])
    db.execute("UPDATE posts
                  SET comments = comments + 1
                  WHERE uuid = ?
                ", data[:post_uuid])
  end

  def self.vote(data)
    comment_id = data[:params]["comment_id"]
    user = data[:user]
    db = SQLite3::Database.new "database.db"
    if data[:params]["upvote"]
      db.execute("UPDATE comments
                      SET upvotes = upvotes + 1
                      WHERE ID = ?
                    ", comment_id)
      db.execute("INSERT INTO user_comment_upvotes
                      (user_id, comment_id)
                      VALUES (?, ?)
                    ", user.id, comment_id)
    elsif data[:params]["downvote"]
      db.execute("UPDATE comments
                      SET downvotes = downvotes + 1
                      WHERE ID = ?
                    ", comment_id)
      db.execute("INSERT INTO user_comment_downvotes
                      (user_id, comment_id)
                      VALUES (?, ?)
                    ", user.id, comment_id)
    elsif data[:params]["removeupvote"]
      db.execute("UPDATE comments
                      SET upvotes = upvotes - 1
                      WHERE ID = ?
                    ", comment_id)
      db.execute("DELETE
                    FROM user_comment_upvotes
                    WHERE comment_id = ?
                    ", comment_id)
    elsif data[:params]["removedownvote"]
      db.execute("UPDATE comments
                      SET downvotes = downvotes - 1
                      WHERE ID = ?
                    ", comment_id)
      db.execute("DELETE
                  FROM user_comment_downvotes
                  WHERE comment_id = ?
                  ", comment_id)
    end
  end
end
