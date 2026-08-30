const bwipjs = require('bwip-js');
const fs = require('fs');
const path = require('path');

const codes = [
  { code: '1234567890123', name: 'Monitor Dell 24"' },
  { code: '9876543210987', name: 'Teclado Mecánico Logitech' },
  { code: '1122334455667', name: 'Portátil ThinkPad T14' }
];

const outputDir = '/home/kairos/.gemini/antigravity-ide/brain/6c04885e-bc0c-470f-8fe4-d0459a07bf77';

codes.forEach((item, index) => {
  bwipjs.toBuffer({
    bcid: 'code128',
    text: item.code,
    scale: 3,
    height: 10,
    includetext: true,
    textxalign: 'center',
  }, function (err, png) {
    if (err) {
      console.error(err);
    } else {
      const p = path.join(outputDir, `barcode_${index + 1}.png`);
      fs.writeFileSync(p, png);
      console.log(`Generated ${p}`);
    }
  });
});
