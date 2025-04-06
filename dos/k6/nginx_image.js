import http from 'k6/http';
import { sleep, check } from 'k6';
import { Counter } from 'k6/metrics';

const failedRequests = new Counter('failed_requests');
const successfulRequests = new Counter('successful_requests');


export const options = {
  stages: [
    { duration: '1m', target: 100 },   // 1分間かけて100ユーザーまで増加
    { duration: '2m', target: 500 },   // 2分間かけて500ユーザーまで増加
    { duration: '2m', target: 1000 },  // 2分間かけて1000ユーザーまで増加
    { duration: '2m', target: 2000 },  // 2分間かけて2000ユーザーまで増加
    { duration: '1m', target: 0 },     // 1分間かけて徐々に減少
  ],
  timeout: '10s',
  thresholds: {
    // 10%未満の失敗率
    http_req_failed: ['rate<0.1'],
    // 95%のリクエストが3秒以内に完了すること
    http_req_duration: ['p(95)<3000'],
    // 失敗リクエスト数が1000未満であること
    failed_requests: ['count<1000'],
  },
};

export default function () {
  const res = http.get("http://nginx:3000/", { timeout: '5s'});
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time is acceptable': (r) => r.timings.duration < 500,
  });

  if(res.status >= 200 && res.status < 400) {
    successfulRequests.add(1);
  } else {
    failedRequests.add(1);
  }
}