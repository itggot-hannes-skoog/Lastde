class Sub < Model
  attr_reader :id, :name, :regdate, :author, :subscribed, :mod, :mods

  table_name "subs"

  def initialize(data)
    @id = data[0]
    @name = data[1]
    @regdate = data[2]
    @reqrank = data[3]
    @author = data[4]
    @subscribed = data[5]
    @mod = data[6]
    @mods = data[7]
  end

  def self.get_mods(name)
    db = SQLite3::Database.new "database.db"
    mods = db.execute("SELECT users.username
                        FROM user_memberships
                        JOIN users ON user_memberships.user_id = users.id
                        WHERE sub_name = ?
                        AND mod = ?",
                      name, "true")
  end

  def self.check_mod(data)
    db = SQLite3::Database.new "database.db"
    mod = db.execute("SELECT mod
                      FROM user_memberships
                      WHERE user_id = ?
                      AND sub_name = ?",
                     data[:user_id], data[:sub_name])
    if mod.empty?
      return false
    else
      return !mod[0][0].nil? ? true : false
    end
  end

  def self.new_sub(data)
    errors = {}
    date = Time.now.strftime("%Y-%m-%d")
    db = SQLite3::Database.new "database.db"
    numbers = (0..9).to_a
    str_numbers = numbers.map(&:to_s)
    chars = ("a".."z").to_a + ("A".."Z").to_a + str_numbers + ["-", "_"]
    if !data[:name].chars.detect { |ch| !chars.include?(ch) }.nil?
      return "Illegal subname, non alphanumeric characters!"
    elsif data[:name].size > 20
      return "Illegal subname, too long!"
    else
      db.execute("INSERT 
                  INTO subs (name, regdate, author)
                  VALUES (?, ?, ?)
                  ", [data[:name], date, data[:user].uname])
      db.execute("INSERT 
                  INTO user_memberships (user_id, sub_name, mod)
                  VALUES (?, ?, ?)
                  ", [data[:user].id, data[:name], "true"])
      return nil
    end
  end

  def self.add_mod(data)
    db = SQLite3::Database.new "database.db"
    name = data[:sub_name]
    user = db.execute("SELECT * FROM user_memberships
                        WHERE user_id = ?
                        AND sub_name = ?
                      ", [data[:user_id], name])
    if user.empty?
      db.execute("INSERT INTO user_memberships
                  (user_id, sub_name, mod)
                  VALUES (?, ?, 'true')
                  ", [data[:user_id], name])
    else
      db.execute("UPDATE user_memberships
                  SET mod = 'true'
                  WHERE user_id = ?
                  AND sub_name = ?
                  ", [data[:user_id], name])
    end
  end

  def self.subscribe(data)
    db = SQLite3::Database.new "database.db"
    name = data[:name]
    user = db.execute("SELECT * FROM user_memberships
                        WHERE user_id = ?
                        AND sub_name = ?
                      ", [data[:user].id, name])
    if user.empty?
      db.execute("INSERT INTO user_memberships
                  (user_id, sub_name, subscribed)
                  VALUES (?, ?, 'true')
                  ", [data[:user].id, name])
    else
      db.execute("UPDATE user_memberships
                  SET subscribed = 'true'
                  WHERE user_id = ?
                  AND sub_name = ?
                  ", [data[:user].id, name])
    end
  end

  def self.unsubscribe(data)
    db = SQLite3::Database.new "database.db"
    name = data[:name]
    db.execute("UPDATE user_memberships
                SET subscribed = null
                WHERE user_id = ?
                AND sub_name = ?
                ", [data[:user].id, name])
  end
end
