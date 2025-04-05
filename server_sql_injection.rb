require 'webrick'
require 'mysql2'

# sample request
# 
# OK
# http://localhost:3000/search?username=admin
# 
# SQL Injection
# http://localhost:3000/search?username=' OR '1 '= '1
# 

# Create MySQL client
client = Mysql2::Client.new(
  host: 'db',
  username: "root",
  password: "password",
  database: "test_db"
)

# Create a simple database
client.query("CREATE TABLE IF NOT EXISTS users (id INT PRIMARY KEY, username VARCHAR(50), password VARCHAR(50))")

# Insert some test data
if client.query("SELECT COUNT(*) FROM users").first["COUNT(*)"] == 0
  client.query("INSERT IGNORE INTO users VALUES (1, 'admin', 'admin-password')")
  client.query("INSERT IGNORE INTO users VALUES (2, 'user', 'user-password')")
end

# Create a WebRick server
server = WEBrick::HTTPServer.new(:Port => 3000)

# user search(vulnerable to SQL injection)
server.mount_proc '/search' do |req, res|
  username = req.query['username']
  
  # Vulnerable SQL query - NO SANITIZATION
  query = "SELECT * FROM users WHERE username = '#{username}'"
  begin
    results = client.query(query)
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