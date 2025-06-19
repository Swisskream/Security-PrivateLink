#!/bin/bash
yum update -y
yum install -y nodejs
cat <<EOF > app.js
const http = require('http");
const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Hello from PrivateLink API!");
});
server.listen(80);
EOF
node app.js