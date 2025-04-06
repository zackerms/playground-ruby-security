require 'webrick'
require 'mysql2'
require 'erb'
require 'connection_pool'

# Create MySQL client
DB_POOL = ConnectionPool.new(size: 5, timeout: 5) do
  Mysql2::Client.new(
    host: 'db',
    username: "root",
    password: "password",
    database: "test_db",
  )
end

DB_POOL.with do |client|
  # Create a simple database
  client.query("CREATE TABLE IF NOT EXISTS users (id INT PRIMARY KEY, username VARCHAR(50), password VARCHAR(50), role VARCHAR(50))")

  # Insert some test data
  if client.query("SELECT COUNT(*) FROM users").first["COUNT(*)"] == 0
    1000.times do |i|
      client.query("INSERT IGNORE INTO users VALUES (#{i}, 'user#{i}', 'password#{i}', 'user')")
    end
  end
end

# Create a WebRick server
server = WEBrick::HTTPServer.new(:Port => 4000)

server.mount('/public', WEBrick::HTTPServlet::FileHandler, 'public')

server.mount_proc '/' do |req, res|
  begin
    DB_POOL.with do |client|
      @users = client.query("SELECT * FROM users")
      template = ERB.new(File.read('erb/index.erb'))
      res.body = template.result(binding)
      res.content_type = 'text/html'
    end
  rescue ConnectionPool::TimeoutError
    res.status = 503
    res.body = "Database connection timeout. Please try again later."
    res.content_type = 'text/plain'
  end
  
end

# terminate server on Ctrl+C
trap('INT') { server.shutdown }

server.start