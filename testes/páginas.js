const { test } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

test('Populate data and generate screenshots for all screens', async ({ page }) => {
  // Listen for console logs and page errors
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  page.on('pageerror', err => console.error('PAGE ERROR:', err.stack || err.message));

  // Viewports configurations
  const viewports = {
    horizontal: { width: 1280, height: 800 },
    vertical: { width: 375, height: 812 }
  };

  // Step 1: Navigate to Tasks, populate some tasks first so screenshots look nice
  console.log('Navigating to /tarefas to pre-populate tasks...');
  await page.goto('/tarefas');
  await page.waitForSelector('a:has-text("Nova Tarefa")', { timeout: 10000 });

  await page.click('a:has-text("Nova Tarefa")');
  await page.waitForSelector('#new-task-title', { timeout: 10000 });
  await page.fill('#new-task-title', 'Comprar mantimentos para a semana');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(200);

  await page.waitForSelector('a:has-text("Nova Tarefa")', { timeout: 10000 });
  await page.click('a:has-text("Nova Tarefa")');
  await page.waitForSelector('#new-task-title', { timeout: 10000 });
  await page.fill('#new-task-title', 'Revisar relatório de desempenho');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(200);

  // Step 2: Navigate to Rotinas and create a routine
  console.log('Navigating to /rotinas to pre-populate routines...');
  await page.goto('/rotinas');
  await page.waitForSelector('#new-routine-title', { timeout: 10000 });

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
  await page.goto('/planos');
  await page.waitForSelector('#new-plan-title', { timeout: 10000 });

  await page.fill('#new-plan-title', 'Lançar novo website pessoal');
  await page.fill('#new-plan-desc', 'Passos necessários para colocar o site no ar de forma profissional.');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(200);

  // Manage tasks on the newly created plan
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
  const routes = ['tarefas', 'tarefas/nova', 'rotinas', 'planos'];

  for (const route of routes) {
    console.log(`Taking screenshots for /${route}...`);
    await page.goto(`/${route}`);
    await page.waitForTimeout(500); // Wait for Elm view transition

    const dir = path.join(__dirname, 'páginas', route);
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
});
