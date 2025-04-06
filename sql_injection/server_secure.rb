require 'webrick'
require 'mysql2'

client = Mysql2::Client.new(
  host: 'db',
  username: "root",
  password: "password",
  database: "test_db"
)

client.query("CREATE TABLE IF NOT EXISTS users (id INT PRIMARY KEY, username VARCHAR(50), password VARCHAR(50), role VARCHAR(50))")

if client.query("SELECT COUNT(*) FROM users").first["COUNT(*)"] == 0
  client.query("INSERT IGNORE INTO users VALUES (1, 'admin', 'admin-password', 'admin')")
  client.query("INSERT IGNORE INTO users VALUES (2, 'alice', 'alice-password', 'user')")
  client.query("INSERT IGNORE INTO users VALUES (3, 'bob', 'bob-password', 'user')")
  client.query("INSERT IGNORE INTO users VALUES (4, 'charlie', 'charlie-password', 'user')")
  client.query("INSERT IGNORE INTO users VALUES (5, 'eve', 'eve-password', 'user')")
end

server = WEBrick::HTTPServer.new(:Port => ENV['PORT'] || 3000)

server.mount_proc '/search' do |req, res|
  username = req.query['username']
  
  # 対策：Prepared Statementsを使用してSQLインジェクションを防止
  stmt = client.prepare("SELECT username FROM users WHERE username = ? AND role = 'user'")
  begin
    results = stmt.execute(username) 
    res.status = 200
    res['Content-Type'] = 'text/plain'
    res.body = results.to_a.inspect
  rescue Mysql2::Error => e
    res.body = "Error: #{e.message}"
  ensure
    # リリースリークを防ぐ
    stmt.close if stmt
  end
end

# terminate server on Ctrl+C
trap('INT') { server.shutdown }

server.start