class Sub
  attr_reader :id, :name, :regdate, :pwd, :subscribed

  def initialize(data)
    @id = data[0]
    @name = data[1]
    @regdate = data[2]
    @reqrank = data[3]
    @subscribed = data[4]
  end

  def self.get(data)
    user = data[:user]
    db = SQLite3::Database.new "database.db"
    if data[:type] == "header"
      if user
        subs = db.execute("SELECT subs.*
                            FROM subs
                            JOIN user_subs ON user_subs.sub_id = subs.id
                            WHERE user_subs.user_id = ?",
                          user.id)
      else
        subs = db.execute("SELECT * FROM subs")
      end
    elsif data[:type] == "sub"
      id = data[:id].to_i
      db = SQLite3::Database.new "database.db"
      subs = db.execute("SELECT *
                          FROM subs
                          WHERE id = ?",
                        id).first
      if user != nil
        subscribed = db.execute("SELECT *
                            FROM user_subs
                            WHERE user_id = ?
                            AND sub_id = ?",
                                user.id, id)
        if !subscribed.empty?
          subs.push(true)
        else
          subs.push(false)
        end
      end
      return Sub.new(subs)
    end
    subs.map { |sub| Sub.new(sub) }
  end

  def self.new_sub(data)
    name = data["name"]
    date = Time.now.strftime("%Y-%m-%d")
    pwd = BCrypt::Password.create(data["pwd"])
    db = SQLite3::Database.new "database.db"
    db.execute("INSERT 
                INTO subs (name, regdate, password)
                VALUES (?, ?, ?)
                ", [name, date, pwd])
  end

  def self.subscribe(id, user)
    db = SQLite3::Database.new "database.db"
    db.execute("INSERT 
                INTO user_subs (user_id, sub_id)
                VALUES (?, ?)
                ", [user.id, id])
  end

  def self.unsubscribe(id, user)
    db = SQLite3::Database.new "database.db"
    db.execute("DELETE
                FROM user_subs
                WHERE user_id = ?
                AND sub_id = ?
                ", [user.id, id])
  end
end
