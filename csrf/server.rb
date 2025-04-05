require 'webrick'
require 'erb'
require 'mysql2'
require 'securerandom'

# セッションクラス (簡易的な実装)
class Session
  @@sessions = {}
  
  def self.create(user_id)
    session_id = SecureRandom.hex(16)
    @@sessions[session_id] = {
      user_id: user_id,
      created_at: Time.now
    }
    return session_id
  end
  
  def self.get(session_id)
    @@sessions[session_id]
  end
  
  def self.destroy(session_id)
    @@sessions.delete(session_id)
  end
end

client = Mysql2::Client.new(
  host: "db",
  username: "root",
  password: "password",
  database: "test_db"
)

# テーブル作成
client.query("DROP TABLE IF EXISTS users")
client.query("CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL
)")

if client.query("SELECT COUNT(*) FROM users").first.values.first == 0
  client.query("INSERT INTO users (username, password, email) VALUES ('alice', 'password', 'alice@example.com')")
end

# WEBrickサーバーの設定
server = WEBrick::HTTPServer.new(
  Port: 3000,
  DocumentRoot: "."
)

server.mount_proc('/') do |req, res|
  res.set_redirect(WEBrick::HTTPStatus::Found, '/login')
end

# ログインページ
server.mount_proc('/login') do |req, res|
  if req.request_method == 'GET'
    template = ERB.new(File.read('erb/login.erb'))
    res.body = template.result(binding)
  elsif req.request_method == 'POST'
    username = req.query['username']
    password = req.query['password']
    
    user = client.query("SELECT * FROM users WHERE username = '#{username}' AND password = '#{password}'").first
    
    if user 
      session_id = Session.create(user['id'])
      res.cookies << WEBrick::Cookie.new('session_id', session_id)
      res.set_redirect(WEBrick::HTTPStatus::Found, '/profile')
    else
      res.set_redirect(WEBrick::HTTPStatus::Found, '/login?error=1')
    end
  end
end

# プロフィールページ
server.mount_proc('/profile') do |req, res|
  # セッション情報を取得
  session_id = req.cookies.find { |c| c.name == 'session_id' }&.value
  session = Session.get(session_id)
 
  # セッションが存在しない場合はログインページへリダイレクト
  if session.nil?
    res.set_redirect(WEBrick::HTTPStatus::Found, '/login')
    next
  end
 
  user = client.query("SELECT * FROM users WHERE id = #{session[:user_id]}").first
 
  if req.request_method == 'GET'
    template = ERB.new(File.read('erb/profile.erb'))
    res.body = template.result(binding)
  end
end

# メールアドレス更新（CSRFに脆弱なエンドポイント）
server.mount_proc('/update_email') do |req, res|
  if req.request_method == 'POST'
    session_id = req.cookies.find { |c| c.name == 'session_id' }&.value
    session = Session.get(session_id)
    
    if session.nil?
      res.set_redirect(WEBrick::HTTPStatus::Found, '/login')
      next
    end
    
    new_email = req.query['email']
    
    # データベース更新
    client.query("UPDATE users SET email = '#{new_email}' WHERE id = #{session[:user_id]}")
    
    res.set_redirect(WEBrick::HTTPStatus::Found, '/profile?updated=1')
  end
end

# ログアウト
server.mount_proc('/logout') do |req, res|
  # セッション情報を削除
  session_id = req.cookies.find { |c| c.name == 'session_id' }&.value
  Session.destroy(session_id)
  res.cookies << WEBrick::Cookie.new('session_id', '')

  res.set_redirect(WEBrick::HTTPStatus::Found, '/login')
end

trap('INT') { server.shutdown }

server.start