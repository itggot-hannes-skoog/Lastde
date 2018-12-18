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
  end

  def self.get(data)
    db = SQLite3::Database.new "database.db"
    if data[:type] == "post"
      uuid = data[:uuid]
      comments = db.execute("SELECT *
                            FROM comments
                            WHERE post_uuid = ?",
                            uuid)
      comments.map { |comment| Comment.new(comment) }
    elsif data[:type] == "user"
      uname = data[:username]
      comments = db.execute("SELECT *
                              FROM comments
                              WHERE author = ?",
                            uname)
      comments.map { |comment| Comment.new(comment) }
    end
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
end
