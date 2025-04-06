import http from 'k6/http';
import { sleep, check } from 'k6';
import { Counter } from 'k6/metrics';

const failedRequests = new Counter('failed_requests');
const successfulRequests = new Counter('successful_requests');


export const options = {
  stages: [
    { duration: '10s', target: 100 },  
    { duration: '10s', target: 500 },  
    { duration: '10s', target: 1000 }, 
  ],
  timeout: '5s',                       
  thresholds: {
    // 10%未満の失敗率
    http_req_failed: ['rate<0.1'],
    // 95%のリクエストが1.5秒以内に完了すること
    http_req_duration: ['p(95)<1500'], 
    // 失敗リクエスト数が500未満であること
    failed_requests: ['count<500'],    
  },
};

export default function () {
  const res = http.get("http://web-image:3000/", { timeout: '5s'});
  
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