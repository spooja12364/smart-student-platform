import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '10s', target: 100 }, // Ramp up to 100 users
    { duration: '1m', target: 100 },  // Stay at 100 users for 1 minute
    { duration: '10s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<3400', 'avg<2000'],
    http_req_failed: ['rate<0.05'],
    checks: ['rate>0.99'],
  },
};

export default function () {
  const baseUrl = __ENV.BASE_URL || 'https://smart-student-platform.web.app';
  
  const res = http.get(baseUrl);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(1);
}

export function handleSummary(data) {
  const p95 = data.metrics.http_req_duration.values.p95;
  const avg = data.metrics.http_req_duration.values.avg;
  const errRate = data.metrics.http_req_failed.values.rate;
  const checksRate = data.metrics.checks ? data.metrics.checks.values.rate : 1;
  
  const p95Pass = p95 < 3400;
  const avgPass = avg < 2000;
  const errPass = errRate < 0.05;
  const checkPass = checksRate > 0.99;
  
  const overallPassed = p95Pass && avgPass && errPass && checkPass;

  let md = `## ⚡ Smart Student App Load Testing — Frontend (100 VUs x 1 Min)\n\n`;
  md += `100 Virtual Users running for 1 minute against the Frontend Application.\n\n`;
  md += `🎯 **Overall Result:** ${overallPassed ? '🟢 PASSED' : '🔴 FAILED'}\n\n`;
  
  md += `### 📊 Metric Summary\n`;
  md += `| Metric | Value |\n`;
  md += `|---|---|\n`;
  md += `| Total Requests | ${data.metrics.http_reqs.values.count} |\n`;
  md += `| Requests / Second | ${data.metrics.http_reqs.values.rate.toFixed(2)} req/s |\n`;
  md += `| Avg Response Time | ${data.metrics.http_req_duration.values.avg.toFixed(2)} ms |\n`;
  md += `| Min Response Time | ${data.metrics.http_req_duration.values.min.toFixed(2)} ms |\n`;
  md += `| p95 Response Time | ${p95.toFixed(2)} ms |\n`;
  md += `| Max Response Time | ${data.metrics.http_req_duration.values.max.toFixed(2)} ms |\n`;
  md += `| HTTP Error Rate | ${(errRate * 100).toFixed(2)}% |\n`;
  md += `| Check Pass Rate | ${(checksRate * 100).toFixed(2)}% |\n\n`;

  md += `### ✅ Threshold Validation\n`;
  md += `| Threshold | Limit | Actual | Status |\n`;
  md += `|---|---|---|---|\n`;
  md += `| p95 Response Time | < 3,400 ms | ${p95.toFixed(2)} ms | ${p95Pass ? '✅ PASS' : '❌ FAIL'} |\n`;
  md += `| Avg Response Time | < 2,000 ms | ${avg.toFixed(2)} ms | ${avgPass ? '✅ PASS' : '❌ FAIL'} |\n`;
  md += `| HTTP Error Rate | < 5% | ${(errRate * 100).toFixed(2)}% | ${errPass ? '✅ PASS' : '❌ FAIL'} |\n`;
  md += `| Check Pass Rate | > 99% | ${(checksRate * 100).toFixed(2)}% | ${checkPass ? '✅ PASS' : '❌ FAIL'} |\n\n`;

  md += `<details><summary><b>What the Numbers Mean</b></summary>\n\n`;
  md += `| Metric | Interpretation |\n`;
  md += `|---|---|\n`;
  md += `| Requests per second | How many requests the server handled every second |\n`;
  md += `| Average response | Typical latency for a user |\n`;
  md += `| Fastest response | Best-case latency |\n`;
  md += `| Slowest response | Worst-case latency |\n`;
  md += `| p95 response | 95% of users experienced this latency or better |\n`;
  md += `</details>\n\n---`;

  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'k6-summary-frontend.md': md,
  };
}

function textSummary(data, options) {
    return "Frontend Load Test Completed.\n";
}
