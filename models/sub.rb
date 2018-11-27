class Sub
  attr_reader :id, :name, :regdate, :pwd, :subscribed

  def initialize(data)
    @id = data[0]
    @name = data[1]
    @regdate = data[2]
    @reqrank = data[3]
    @subscribed = data[4]
  end

  def self.get(id, user)
    id.to_i
    db = SQLite3::Database.new "database.db"
    data = db.execute("	SELECT *
                        FROM subs
                        WHERE id = ?",
                      id).first
    if user != nil
      subs = db.execute("	SELECT *
                          FROM user_subs
                          WHERE user_id = ?
                          AND sub_id = ?",
                        user.id, id)
      if !subs.empty?
        data.push(true)
      else
        data.push(false)
      end
    end
    Sub.new(data)
  end

  def self.auth(data)
    pwd = data[0]
    id = data[1]
    db = SQLite3::Database.new "database.db"
    pwd = db.execute("SELECT pwd
                      FROM subs
                      WHERE id = ?",
                     id).first
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
