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
    execSync('npx elm make src/Main.elm --output dist/elm.js --optimize', { stdio: 'inherit' });
} catch (e) {
    console.warn('Elm compilation with --optimize failed (this is normal in development). Compiling normally...');
    execSync('npx elm make src/Main.elm --output dist/elm.js', { stdio: 'inherit' });
}

// Copy public assets
console.log('Copying public assets...');
fs.copyFileSync(path.join('public', 'index.html'), path.join('dist', 'index.html'));
fs.copyFileSync(path.join('public', 'app.js'), path.join('dist', 'app.js'));
if (fs.existsSync(path.join('public', 'brand-icon.png'))) {
    fs.copyFileSync(path.join('public', 'brand-icon.png'), path.join('dist', 'brand-icon.png'));
}

// Create _redirects file for Cloudflare Pages SPA routing
console.log('Creating _redirects file for Cloudflare Pages...');
const redirectRules = [
    '/tarefas /index.html 200',
    '/rotinas /index.html 200',
    '/planos /index.html 200'
].join('\n') + '\n';

fs.writeFileSync(path.join('dist', '_redirects'), redirectRules, 'utf-8');

console.log('Build completed successfully!');
