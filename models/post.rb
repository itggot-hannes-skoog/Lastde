class Post
  attr_reader :id, :title, :textbody, :timestamp, :sub_id, :uuid, :sub_name, :author, :upvotes, :downvotes, :comments, :upvoted, :downvoted

  def initialize(data)
    @id = data[0]
    @title = data[1]
    @textbody = data[2]
    @timestamp = data[3]
    @img = data[4]
    @sub_id = data[5]
    @uuid = data[6]
    @author = data[7]
    @upvotes = data[8]
    @downvotes = data[9]
    @sub_name = data[10]
    @comments = data[11]
    @upvoted = data[12]
    @downvoted = data[13]
  end

  def self.get(data)
    db = SQLite3::Database.new "database.db"
    name = data[:sub_name]
    id = db.execute("SELECT id FROM subs WHERE name = ?", name).first
    if data[:type] == "startpage"
      if data[:user]
        user = data[:user]
        posts = db.execute("SELECT posts.*, subs.name AS sub_name
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
      uname = data[:username]
      posts = db.execute("SELECT posts.*, subs.name
                          FROM posts
                          JOIN subs 
                          ON posts.sub_id = subs.ID
                          WHERE posts.author = ?
                          ORDER BY dateTime(timestamp)
                          DESC",
                         uname)
    elsif data[:type] == "post"
      uuid = data[:uuid]
      posts = db.execute("SELECT posts.*, subs.name 
                          AS sub_name
                          FROM posts 
                          JOIN subs 
                          ON posts.sub_id = subs.ID 
                          WHERE sub_id = ?
                          AND uuid = ?",
                         id, uuid)
    end
    posts.each do |post|
      comments = db.execute("SELECT count(*)
                              FROM comments
                              WHERE post_uuid = ?
                            ", post[6])
      post.push(comments.first.first)
    end
    if data[:user]
      user = data[:user]
      upvoted = db.execute("SELECT post_uuid
                            FROM user_upvotes
                            WHERE user_id = ?",
                           user.id)
      downvoted = db.execute("SELECT post_uuid
                            FROM user_downvotes
                            WHERE user_id = ?",
                             user.id)
      upvoted = upvoted.map { |upvote| upvote.first }
      downvoted = downvoted.map { |downvote| downvote.first }
      posts.each do |post|
        if upvoted.include? post[6]
          post.push(true)
        else
          post.push(false)
        end
        if downvoted.include? post[6]
          post.push(true)
        else
          post.push(false)
        end
      end
    else
      posts.each { |post| post += [false, false] }
    end
    posts.map { |post| Post.new(post) }
  end

  def self.new_post(data)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
    uuid = SecureRandom.urlsafe_base64(8, false)
    img = ""
    user = data[:user]
    name = data[:sub_name]
    id = db.execute("SELECT id FROM subs WHERE name = ?", name).first
    db = SQLite3::Database.new "database.db"
    db.execute("INSERT INTO posts
                (title, textbody, timestamp, sub_id, uuid, author, upvotes, downvotes)
                VALUES (?, ?, ?, ?, ?, ?, 1, 0)
                ", [data[:title], data[:textbody], timestamp, id, uuid, user.uname])

    db.execute("INSERT INTO user_upvotes
                (user_id, post_uuid)
                VALUES (?, ?)
              ", user.id, uuid)
  end

  def self.vote(data)
    uuid = data[:uuid]
    user = data[:user]
    db = SQLite3::Database.new "database.db"
    if data[:type] == "upvote"
      db.execute("UPDATE posts
                    SET upvotes = upvotes + 1
                    WHERE uuid = ?
                  ", uuid)
      db.execute("INSERT INTO user_upvotes
                    (user_id, post_uuid)
                    VALUES (?, ?)
                  ", user.id, uuid)
    elsif data[:type] == "downvote"
      db.execute("UPDATE posts
                    SET downvotes = downvotes + 1
                    WHERE uuid = ?
                  ", uuid)
      db.execute("INSERT INTO user_downvotes
                  (user_id, post_uuid)
                  VALUES (?, ?)
                  ", user.id, uuid)
    elsif data[:type] == "removeupvote"
      db.execute("UPDATE posts
                    SET upvotes = upvotes - 1
                    WHERE uuid = ?
                  ", uuid)
      db.execute("DELETE
                  FROM user_upvotes
                  WHERE post_uuid = ?
                  ", uuid)
    elsif data[:type] == "removedownvote"
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
end
