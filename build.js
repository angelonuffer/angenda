const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('Starting build...');

// Ensure dist directory exists
if (!fs.existsSync('dist')) {
    fs.mkdirSync('dist', { recursive: true });
}

// Compile Elm to dist/elm.js
console.log('Compiling Elm...');
try {
    execSync('elm make src/Main.elm --output dist/elm.js --optimize', { stdio: 'inherit' });
} catch (e) {
    console.warn('Elm compilation with --optimize failed (this is normal in development). Compiling normally...');
    execSync('elm make src/Main.elm --output dist/elm.js', { stdio: 'inherit' });
}

// Copy public assets
console.log('Copying public assets...');
fs.copyFileSync(path.join('public', 'index.html'), path.join('dist', 'index.html'));
fs.copyFileSync(path.join('public', 'app.js'), path.join('dist', 'app.js'));

console.log('Build completed successfully!');
