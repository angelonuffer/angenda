const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const PORT = 3000;
const DIST_DIR = path.join(__dirname, '..', 'dist');

// Create test server
const server = http.createServer((req, res) => {
    let filePath = path.join(DIST_DIR, req.url.split('?')[0]);
    if (filePath === DIST_DIR || filePath.endsWith('/')) {
        filePath = path.join(filePath, 'index.html');
    }

    if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        filePath = path.join(DIST_DIR, 'index.html');
    }

    const ext = path.extname(filePath);
    let contentType = 'text/html';
    if (ext === '.js') contentType = 'text/javascript';
    else if (ext === '.css') contentType = 'text/css';
    else if (ext === '.json') contentType = 'application/json';
    else if (ext === '.png') contentType = 'image/png';
    else if (ext === '.jpg') contentType = 'image/jpeg';
    else if (ext === '.svg') contentType = 'image/svg+xml';

    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(500);
            res.end(`Server Error: ${err.code}`);
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

// Start the server and run screenshots
server.listen(PORT, async () => {
    console.log(`Test server running on port ${PORT}`);

    let browser;
    try {
        console.log('Launching browser...');
        browser = await chromium.launch({ headless: true });
        const context = await browser.newContext();

        // Viewports configurations
        const viewports = {
            horizontal: { width: 1280, height: 800 },
            vertical: { width: 375, height: 812 }
        };

        const page = await context.newPage();

        // Listen for console logs and page errors
        page.on('console', msg => console.log('PAGE LOG:', msg.text()));
        page.on('pageerror', err => console.error('PAGE ERROR:', err.stack || err.message));

        // Step 1: Navigate to Tasks, populate some tasks first so screenshots look nice
        console.log('Navigating to /tarefas to pre-populate tasks...');
        await page.goto(`http://localhost:${PORT}/tarefas`);
        await page.waitForSelector('#new-task-title', { timeout: 5000 });

        await page.fill('#new-task-title', 'Comprar mantimentos para a semana');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(200);

        await page.fill('#new-task-title', 'Revisar relatório de desempenho');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(200);

        // Step 2: Navigate to Rotinas and create a routine
        console.log('Navigating to /rotinas to pre-populate routines...');
        await page.goto(`http://localhost:${PORT}/rotinas`);
        await page.waitForSelector('#new-routine-title', { timeout: 5000 });

        await page.fill('#new-routine-title', 'Fazer exercícios físicos');
        await page.selectOption('#new-routine-recurrence', 'Diária');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(200);

        await page.fill('#new-routine-title', 'Limpar área de trabalho');
        await page.selectOption('#new-routine-recurrence', 'Semanal');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(200);

        // Generate a task from the first routine
        await page.click('button:has-text("Gerar Tarefa")');
        await page.waitForTimeout(200);

        // Step 3: Navigate to Planos and create a plan
        console.log('Navigating to /planos to pre-populate plans...');
        await page.goto(`http://localhost:${PORT}/planos`);
        await page.waitForSelector('#new-plan-title', { timeout: 5000 });

        await page.fill('#new-plan-title', 'Lançar novo website pessoal');
        await page.fill('#new-plan-desc', 'Passos necessários para colocar o site no ar de forma profissional.');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(200);

        // Manage tasks on the newly created plan
        // The plan id starts with plan_... we can find the manage button easily by text
        await page.click('button:has-text("Gerenciar Tarefas")');
        await page.waitForSelector('#new-plan-task');

        await page.fill('#new-plan-task', 'Registrar domínio .com.br');
        await page.click('#add-plan-task-btn');
        await page.waitForTimeout(200);

        await page.fill('#new-plan-task', 'Configurar hospedagem na Cloudflare');
        await page.click('#add-plan-task-btn');
        await page.waitForTimeout(200);

        await page.fill('#new-plan-task', 'Subir arquivos do build');
        await page.click('#add-plan-task-btn');
        await page.waitForTimeout(200);

        // Complete the first step of the plan
        await page.click('ol li button');
        await page.waitForTimeout(200);

        // Close the manager view
        await page.click('button:has-text("Fechar")');
        await page.waitForTimeout(200);

        // Now take the screenshots for each route and layout!
        const routes = ['tarefas', 'rotinas', 'planos'];

        for (const route of routes) {
            console.log(`Taking screenshots for /${route}...`);
            await page.goto(`http://localhost:${PORT}/${route}`);
            await page.waitForTimeout(500); // Wait for Elm view transition

            const dir = path.join(__dirname, 'telas', route);
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }

            for (const [layout, viewport] of Object.entries(viewports)) {
                await page.setViewportSize(viewport);
                await page.waitForTimeout(200); // Allow render adjustment

                const screenshotPath = path.join(dir, `${layout}.png`);
                await page.screenshot({ path: screenshotPath, fullPage: false });
                console.log(`Saved ${screenshotPath}`);
            }
        }

        console.log('All screenshooting successfully finished!');
        process.exit(0);
    } catch (err) {
        console.error('Error during screenshooting:', err);
        process.exit(1);
    } finally {
        if (browser) {
            await browser.close();
        }
        server.close();
    }
});
