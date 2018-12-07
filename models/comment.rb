class Comment
  attr_reader :textbody, :timestamp, :uuid, :author

  def initialize(data)
    @id = data[0]
    @textbody = data[1]
    @timestamp = data[2]
    @uuid = data[3]
    @author = data[4]
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
      uname = data[:user]
      comments = db.execute("SELECT *
                              FROM comments
                              WHERE author = ?",
                            uname)
      comments.map { |comment| Comment.new(comment) }
    end
  end

  def self.new_comment(data, user)
    textbody = data["textbody"]
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
    post_uuid = data["uuid"]
    author = user.uname
    db = SQLite3::Database.new "database.db"
    db.execute("INSERT INTO comments
                    (textbody, timestamp, post_uuid, author)
                    VALUES (?, ?, ?, ?)
                    ", [textbody, timestamp, post_uuid, author])
  end
end
