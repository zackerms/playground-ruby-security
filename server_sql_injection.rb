require 'webrick'
require 'mysql2'

# Create MySQL client
client = Mysql2::Client.new(
  host: 'db',
  username: "root",
  password: "password",
  database: "test_db"
)

# Create a simple database
client.query("CREATE TABLE IF NOT EXISTS users (id INT PRIMARY KEY, username VARCHAR(50), password VARCHAR(50), role VARCHAR(50))")

# Insert some test data
if client.query("SELECT COUNT(*) FROM users").first["COUNT(*)"] == 0
  client.query("INSERT IGNORE INTO users VALUES (1, 'admin', 'admin-password', 'admin')")
  client.query("INSERT IGNORE INTO users VALUES (2, 'alice', 'alice-password', 'user')")
  client.query("INSERT IGNORE INTO users VALUES (3, 'bob', 'bob-password', 'user')")
  client.query("INSERT IGNORE INTO users VALUES (4, 'charlie', 'charlie-password', 'user')")
  client.query("INSERT IGNORE INTO users VALUES (5, 'eve', 'eve-password', 'user')")
end

client.query("INSERT IGNORE INTO users VALUES (1, 'admin', 'admin-password', 'admin')")
client.query("INSERT IGNORE INTO users VALUES (2, 'alice', 'alice-password', 'user')")
client.query("INSERT IGNORE INTO users VALUES (3, 'bob', 'bob-password', 'user')")
client.query("INSERT IGNORE INTO users VALUES (4, 'charlie', 'charlie-password', 'user')")
client.query("INSERT IGNORE INTO users VALUES (5, 'eve', 'eve-password', 'user')")

# Create a WebRick server
server = WEBrick::HTTPServer.new(:Port => 3000)

# user search(vulnerable to SQL injection)
# sample request
# 
# OK
# http://localhost:3000/search?username=alice
# 
# SQL Injection(all users)
# http://localhost:3000/search?username=' OR '1' = '1
#
# SQL Injection(all users with role admin)
# http://localhost:3000/search?username=' OR role = 'admin' OR '1' = '1
#
# SQL Injection(all users with role admin)
# http://localhost:3000/find?username=user' OR '1'= '1' --
#
# SQL Injection(all users with role admin)
# http://localhost:3000/search?username=' OR 1 = 1 UNION SELECT username FROM users WHERE '1' = '1
#
# SQL Injection(show tables)
# http://localhost:3000/search?username=' UNION SELECT table_name FROM information_schema.columns WHERE table_schema=database() -- 
# 
server.mount_proc '/search' do |req, res|
  username = req.query['username']
  
  # Vulnerable SQL query - NO SANITIZATION
  query = "SELECT username FROM users WHERE username = '#{username}' AND role = 'user'"
  begin
    results = client.query(query)
    res.status = 200
    res['Content-Type'] = 'text/plain'
    res.body = results.to_a.inspect
  rescue Mysql2::Error => e
    res.body = "Error: #{e.message}"
  end
end

server.mount_proc '/find' do |req, res|
  username = req.query['username']
  query = "SELECT * FROM users WHERE username = '#{username}' AND role = 'user'"
  begin
    results = client.query(query).first
    res.status = 200
    res['Content-Type'] = 'text/plain'
    res.body = results.to_a.inspect
  rescue Mysql2::Error => e
    res.body = "Error: #{e.message}"
  end
end

# terminate server on Ctrl+C
trap('INT') { server.shutdown }

server.start