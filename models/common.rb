class Common
  def self.login(data)
  end

  def self.register(data)
    username = data["username"]
    email = data["email"]
    date = Time.now.strftime("%Y-%m-%d")
    pwd = BCrypt::Password.create(data["pwd"])
    uuid = SecureRandom.uuid
    if data["file"] == []
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
