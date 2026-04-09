'use strict';
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const jscPath = path.join(__dirname, 'server.jsc');
if (!fs.existsSync(jscPath)) {
  console.error('❌ 找不到 server.jsc，程序文件可能不完整');
  process.exit(1);
}

const hash = crypto.createHash('sha256').update(fs.readFileSync(jscPath)).digest('hex');
const expected = '6a344d55d399cd71bcb86a37b04866a8341454c31158df947e9d80033e23735b';
if (hash !== expected) {
  console.error('❌ 程序文件损坏或被篡改，拒绝启动');
  process.exit(1);
}

require('bytenode');
require('./server.jsc');
