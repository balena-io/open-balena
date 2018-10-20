'use strict';

var crypto = require('crypto');
var fs = require('fs');

var base32 = (function() {
  // Extracted from https://github.com/chrisumbel/thirty-two
  // to avoid having to install packages for this script.
  var charTable = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  var byteTable = [
    0xff, 0xff, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06,
    0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e,
    0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16,
    0x17, 0x18, 0x19, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06,
    0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e,
    0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16,
    0x17, 0x18, 0x19, 0xff, 0xff, 0xff, 0xff, 0xff
  ];

  function quintetCount(buff) {
    var quintets = Math.floor(buff.length / 5);
    return buff.length % 5 == 0 ? quintets: quintets + 1;
  }

  return function(plain) {
    if (!Buffer.isBuffer(plain)) {
      plain = Buffer.alloc(plain);
    }
    var i = 0;
    var j = 0;
    var shiftIndex = 0;
    var digit = 0;
    var encoded = Buffer.alloc(quintetCount(plain) * 8);

    /* byte by byte isn't as pretty as quintet by quintet but tests a bit
      faster. will have to revisit. */
    while(i < plain.length) {
      var current = plain[i];
    
      if(shiftIndex > 3) {
        digit = current & (0xff >> shiftIndex);
        shiftIndex = (shiftIndex + 5) % 8;
        digit = (digit << shiftIndex) | ((i + 1 < plain.length) ?
          plain[i + 1] : 0) >> (8 - shiftIndex);
        i++;
      } else {
        digit = (current >> (8 - (shiftIndex + 5))) & 0x1f;
        shiftIndex = (shiftIndex + 5) % 8;            
        if(shiftIndex == 0) i++;
      }
      
      encoded[j] = charTable.charCodeAt(digit);
      j++;
    }

    for (i = j; i < encoded.length; i++) {
      encoded[i] = 0x3d; //'='.charCodeAt(0)
    }
    return encoded;
  }
})();

function joseKeyId(der) {
  var hasher = crypto.createHash('sha256');
  hasher.update(der);
  var b32 = base32(hasher.digest().slice(0, 30)).toString('ascii');
  var chunks = [];
  for (var i = 0; i < b32.length; i += 4) {
    chunks.push(b32.substr(i, 4));
  }
  return chunks.join(':');
}

var derFilePath = process.argv[2];
var der = fs.readFileSync(derFilePath);
process.stdout.write(joseKeyId(der));
