require 'webrick'
require 'mysql2'
require 'cgi'

server = WEBrick::HTTPServer.new(
  :Port => ENV['PORT'] || 3000,
  :DocumentRoot => "./"
)

client = Mysql2::Client.new(
  host: 'db',
  username: "root",
  password: "password",
  database: "test_db"
)

client.query("CREATE TABLE IF NOT EXISTS messages (id INT AUTO_INCREMENT PRIMARY KEY, message TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")

server.mount_proc('/') do |req, res|
  if req.request_method == 'POST'
    message = req.query['message']
    # SQL Injection対策
    stmt = client.prepare("INSERT INTO messages (message) VALUES (?)")
    stmt.execute(message)
    res.set_redirect(WEBrick::HTTPStatus::SeeOther, '/')
  else
    messages = client.query("SELECT * FROM messages ORDER BY created_at DESC")

    template = ERB.new(File.read('erb/index_secure.erb'))

    res.body = template.result(binding)
    res.content_type = 'text/html'
  end
end

trap('INT') { server.shutdown }

server.start