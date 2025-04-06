# CSRF

- ユーザ名: alice（脆弱なページで生成される）
  - パスワード: password
  - 初期メールアドレス: alice@example.com
- ユーザ名: bob（CSRF対策がされたページで生成される）
  - パスワード: password
  - 初期メールアドレス: bob@example.com

|URL|説明|
|---|---|
|http://localhost:3000/|脆弱なページ|
|http://localhost:4000/|CSRF対策がされたページ|
|http://localhost:8000/attack|攻撃者のページ（アクセスした瞬間に脆弱なページに攻撃が行われる）|
|http://localhost:8000/attack_secure|攻撃者のページ（アクセスした瞬間に対策がされたページに攻撃が行われる）|