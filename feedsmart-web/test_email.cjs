const https = require('https');

const data = JSON.stringify({
  service_id: 'service_hrowx0v',
  template_id: 'template_kldht6j',
  user_id: '0SSH8Hp7Vq8L7F_p-',
  template_params: {
    email: 'test@test.com',
    to_email: 'test@test.com',
    user_email: 'test@test.com',
    recipient: 'test@test.com',
    otp: '1234',
    message: '1234'
  }
});

const options = {
  hostname: 'api.emailjs.com',
  port: 443,
  path: '/api/v1.0/email/send',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data),
    'Origin': 'https://smart-student-platform-fe510.web.app',
    'User-Agent': 'Mozilla/5.0'
  }
};

const req = https.request(options, (res) => {
  console.log(`STATUS: ${res.statusCode}`);
  res.on('data', (d) => {
    process.stdout.write(d);
  });
});

req.on('error', (e) => {
  console.error(`error: ${e.message}`);
});

req.write(data);
req.end();
