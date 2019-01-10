class Comment
  attr_reader :id, :textbody, :timestamp, :uuid, :author, :upvotes, :downvotes

  def initialize(data)
    @id = data[0]
    @textbody = data[1]
    @timestamp = data[2]
    @uuid = data[3]
    @author = data[4]
    @upvotes = data[5]
    @downvotes = data[6]
    @upvoted = data[7]
    @downvoted = data[8]
  end

  def self.get(data)
    db = SQLite3::Database.new "database.db"
    if data[:type] == "post"
      uuid = data[:uuid]
      comments = db.execute("SELECT *
                            FROM comments
                            WHERE post_uuid = ?",
                            uuid)
    elsif data[:type] == "user"
      uname = data[:username]
      comments = db.execute("SELECT *
                              FROM comments
                              WHERE author = ?",
                            uname)
    end
    if data[:user]
      user = data[:user]
      upvoted = db.execute("SELECT comment_id
                            FROM user_comment_upvotes
                            WHERE user_id = ?",
                           user.id)
      downvoted = db.execute("SELECT comment_id
                              FROM user_comment_downvotes
                              WHERE user_id = ?",
                             user.id)
      upvoted = upvoted.map { |upvote| upvote.first }
      downvoted = downvoted.map { |downvote| downvote.first }
      comments.each do |comment|
        if upvoted.include? comment[0]
          comment.push(true)
        else
          comment.push(false)
        end
        if downvoted.include? comment[0]
          comment.push(true)
        else
          comment.push(false)
        end
      end
    else
      comments.each { |comment| comment += [false, false] }
    end
    comments.map { |comment| Comment.new(comment) }
  end

  def self.new_comment(data)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
    author = data[:user].uname
    db = SQLite3::Database.new "database.db"
    db.execute("INSERT INTO comments
                    (textbody, timestamp, post_uuid, author, upvotes, downvotes)
                    VALUES (?, ?, ?, ?, 1, 0)
                    ", [data[:textbody], timestamp, data[:post_uuid], author])
  end

  def self.vote(data)
    comment_id = data[:comment_id]
    user = data[:user]
    db = SQLite3::Database.new "database.db"
    if data[:type] == "upvote"
      db.execute("UPDATE comments
                      SET upvotes = upvotes + 1
                      WHERE ID = ?
                    ", comment_id)
      db.execute("INSERT INTO user_comment_upvotes
                      (user_id, comment_id)
                      VALUES (?, ?)
                    ", user.id, comment_id)
    elsif data[:type] == "downvote"
      db.execute("UPDATE comments
                      SET downvotes = downvotes + 1
                      WHERE ID = ?
                    ", comment_id)
      db.execute("INSERT INTO user_comment_downvotes
                      (user_id, comment_id)
                      VALUES (?, ?)
                    ", user.id, comment_id)
    elsif data[:type] == "removeupvote"
      db.execute("UPDATE comments
                      SET upvotes = upvotes - 1
                      WHERE ID = ?
                    ", comment_id)
      db.execute("DELETE
                    FROM user_comment_upvotes
                    WHERE comment_id = ?
                    ", comment_id)
    elsif data[:type] == "removedownvote"
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
