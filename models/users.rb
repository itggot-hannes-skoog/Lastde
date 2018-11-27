class Users
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

  def self.get(id)
    id.to_i
    db = SQLite3::Database.new "database.db"
    user = db.execute("	SELECT *
                        FROM users
                        WHERE id = ?",
                      id).first
    Users.new(user)
  end
end
