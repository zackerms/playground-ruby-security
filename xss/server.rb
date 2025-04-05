require 'webrick'
require 'mysql2'

server = WEBrick::HTTPServer.new(
  :Port => 3000,
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
    # ===============================
    # 新規メッセージ作成
    # ===============================
    message = req.query['message']

    # XSS脆弱性: ユーザー入力を無害化せずに直接データベースに保存
    client.query("INSERT INTO messages (message) VALUES ('#{message}')")
    # See other
    res.set_redirect(WEBrick::HTTPStatus::SeeOther, '/')
  else
    # ===============================
    # メッセージ一覧表示
    # ===============================
    messages = client.query("SELECT * FROM messages ORDER BY created_at DESC")

    template = ERB.new(File.read('erb/index.erb'))

    res.body = template.result(binding)
    res.content_type = 'text/html'
  end
end

trap('INT') { server.shutdown }

server.start