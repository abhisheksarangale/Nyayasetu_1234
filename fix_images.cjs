const fs = require('fs');
const path = require('path');

const lawyersDir = path.join(__dirname, 'Frontend/images/lawyers');
const availableImages = fs.readdirSync(lawyersDir).filter(f => f.endsWith('.jpg'));

const serverTsPath = path.join(__dirname, 'server.ts');
let serverTs = fs.readFileSync(serverTsPath, 'utf8');

// Find all used images that actually exist
const currentImageRegex = /"profile_photo_path":\s*"([^"]+)"/g;
let match;
const usedImages = new Set();
const missingImages = [];

let updatedServerTs = serverTs;

// Gather what's currently in there
const lines = serverTs.split('\n');
const missingLines = [];
lines.forEach((line, index) => {
  const lineMatch = line.match(/"profile_photo_path":\s*"([^"]+)"/);
  if (lineMatch) {
    const img = lineMatch[1];
    if (availableImages.includes(img)) {
      usedImages.add(img);
    } else {
      missingLines.push({ index, img });
    }
  }
});

console.log(`Found ${missingLines.length} missing image entries.`);

// Shuffle available images and pick ones not heavily used, or just cycle through
let availablePool = availableImages.filter(img => !usedImages.has(img));
// If we run out of totally unused images, we'll just shuffle all available ones
if (availablePool.length < missingLines.length) {
    console.log("Not enough completely unused images, will reuse some.");
    availablePool = [...availablePool, ...availableImages].sort(() => Math.random() - 0.5);
} else {
    availablePool = availablePool.sort(() => Math.random() - 0.5);
}

missingLines.forEach((missing, i) => {
    const newImg = availablePool[i % availablePool.length];
    lines[missing.index] = lines[missing.index].replace(missing.img, newImg);
    console.log(`Replaced ${missing.img} with ${newImg} on line ${missing.index + 1}`);
});

fs.writeFileSync(serverTsPath, lines.join('\n'));
console.log('Done replacing missing images.');
