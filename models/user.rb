class User < Model
  attr_reader :id, :uname, :email, :img, :regdate, :level, :role, :mods
  attr_accessor :mod

  table_name "users"

  def initialize(data)
    @id = data[0]
    @uname = data[1]
    @email = data[2]
    @img = data[3]
    @regdate = data[4]
    @level = data[5]
    @password = data[6]
    @role = data[7]
    @mod = false
    @mods = data[8]
  end

  def self.get_mod(data)
    db = SQLite3::Database.new "database.db"
    db.execute("SELECT user_memberships.sub_name
                FROM user_memberships
                JOIN users ON user_memberships.user_id = users.id
                WHERE user_memberships.user_id = ?
                AND mod = ?",
               id, "true")
  end

  def self.login(data)
    db = SQLite3::Database.new "database.db"
    user = db.execute("SELECT id, password
                        FROM users
                        WHERE username = ?", data[:username]).first
    if user == nil
      return {loggedin: false, error: "username"}
    end
    hashed_pwd = BCrypt::Password.new(user[1])
    if hashed_pwd == data[:password]
      return {loggedin: true, user: user}
    else
      return {loggedin: false, error: "pwd"}
    end
  end

  def self.register(data)
    username = data["username"]
    email = data["email"]
    date = Time.now.strftime("%Y-%m-%d")
    pwd = BCrypt::Password.create(data["pwd"])
    uuid = SecureRandom.uuid
    if data["file"]
      tempfile = data["file"][:tempfile]
      filename = data["file"][:filename]
      FileUtils.copy(tempfile.path, "./public/img/#{filename}")
      File.rename("./public/img/#{filename}", "./public/img/#{uuid}.jpg")
    else
      uuid = "default"
    end

    db = SQLite3::Database.new "database.db"
    db.execute("INSERT 
                    INTO users (username, email, img, regdate, password)
                    VALUES (?, ?, ?, ?, ?)
                    ", [username, email, uuid, date, pwd])
  end
end
