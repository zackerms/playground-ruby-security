## 環境構築
```
docker compose up -d
```

## 負荷テストを実行
```sh
docker compose run --rm -e ENDPOINT=http://web-image:3000 k6 run /scripts/http.js

docker compose run --rm -e ENDPOINT=http://nginx:80 k6 run /scripts/http.js
```
