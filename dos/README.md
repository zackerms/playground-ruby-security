## 環境構築
```
docker compose up -d
```

## 負荷テストを実行
```sh
docker compose run k6 run /scripts/server.js

docker compose run k6 run /scripts/nginx.js
```
