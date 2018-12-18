class User
  attr_reader :id, :uname, :email, :img, :regdate, :level, :role

  def initialize(data)
    @id = data[0]
    @uname = data[1]
    @email = data[2]
    @img = data[3]
    @regdate = data[4]
    @level = data[5]
    @password = data[6]
    @role = data[7]
  end

  def self.get(data)
    db = SQLite3::Database.new "database.db"
    if data[:type] == "session"
      id = data[:id].to_i
      user = db.execute("SELECT *
                          FROM users
                          WHERE id = ?",
                        id).first
    elsif data[:type] == "userpage"
      uname = data[:username]
      user = db.execute("SELECT *
                          FROM users
                          WHERE username = ?",
                        uname).first
    end
    User.new(user)
  end

  def self.login(data)
    db = SQLite3::Database.new "database.db"
    user = db.execute("SELECT id, password
                        FROM users
                        WHERE username = ?", data[:username]).first
    if user == nil
      return {loggedin: false}
    end
    hashed_pwd = BCrypt::Password.new(user[1])
    if hashed_pwd == data[:password]
      return {loggedin: true, user: user}
    else
      return {loggedin: false}
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
