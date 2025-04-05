require 'webrick'
require 'erb'

# 攻撃者のWEBrickサーバー設定
server = WEBrick::HTTPServer.new(
  Port: 4000,
  DocumentRoot: "."
)

# CSRF攻撃ページ
server.mount_proc('/') do |req, res|
  template = ERB.new(File.read('erb/attack.erb'))
  res.body = template.result(binding)
end

trap('INT') { server.shutdown }

server.start