const { test, expect } = require('@playwright/test');
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

  await page.waitForSelector('#btn-nova-rotina', { timeout: 10000 });
  await page.click('#btn-nova-rotina');

  await page.waitForSelector('#new-routine-title', { timeout: 10000 });
  await page.fill('#new-routine-title', 'Fazer exercícios físicos');
  await page.selectOption('#new-routine-recurrence', 'Diária');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(200);

  await page.waitForSelector('#btn-nova-rotina', { timeout: 10000 });
  await page.click('#btn-nova-rotina');

  await page.waitForSelector('#new-routine-title', { timeout: 10000 });
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
  await page.waitForSelector('a:has-text("Criar Plano")', { timeout: 10000 });
  await page.click('a:has-text("Criar Plano")');
  await page.waitForSelector('#new-plan-title', { timeout: 10000 });

  await page.fill('#new-plan-title', 'Lançar novo website pessoal');
  await page.fill('#new-plan-desc', 'Passos necessários para colocar o site no ar de forma profissional.');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(200);

  // Edit the newly created plan
  await page.click('a:has-text("Editar")');
  await page.waitForSelector('#add-plan-task-btn');

  // Step 3a: Add first plan task via the new page
  await page.click('#add-plan-task-btn');
  await page.waitForSelector('#new-task-title');
  await page.fill('#new-task-title', 'Registrar domínio .com.br');
  await page.click('button[type="submit"]');
  await page.waitForSelector('#add-plan-task-btn');
  await page.waitForTimeout(200);

  // Step 3b: Add second plan task
  await page.click('#add-plan-task-btn');
  await page.waitForSelector('#new-task-title');
  await page.fill('#new-task-title', 'Configurar hospedagem na Cloudflare');
  await page.click('button[type="submit"]');
  await page.waitForSelector('#add-plan-task-btn');
  await page.waitForTimeout(200);

  // Step 3c: Add third plan task
  await page.click('#add-plan-task-btn');
  await page.waitForSelector('#new-task-title');
  await page.fill('#new-task-title', 'Subir arquivos do build');
  await page.click('button[type="submit"]');
  await page.waitForSelector('#add-plan-task-btn');
  await page.waitForTimeout(200);

  // Complete the first step of the plan
  await page.click('ol li button');
  await page.waitForTimeout(200);

  // Close the edit view
  await page.click('a:has-text("Cancelar")');
  await page.waitForTimeout(200);

  // Step 4: Edit a task
  console.log('Editing the first task...');
  await page.goto('/tarefas');
  await page.waitForSelector('a[title="Editar Tarefa"]', { timeout: 10000 });
  await page.click('a[title="Editar Tarefa"]');
  await page.waitForSelector('#new-task-title', { timeout: 10000 });
  await page.fill('#new-task-title', 'Comprar mantimentos para a semana inteira');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(500);

  // Step 5: Archive the first task
  console.log('Archiving the first task...');
  await page.goto('/tarefas');
  await page.waitForSelector('button[title="Arquivar Tarefa"]', { timeout: 10000 });
  await page.click('button[title="Arquivar Tarefa"]');
  await page.waitForTimeout(500);

  // Step 6: Verify drawer open/close and menu navigation works
  console.log('Verifying drawer toggling and navigation...');
  await page.setViewportSize(viewports.vertical);
  await page.goto('/tarefas');
  await page.waitForSelector('button[title="Menu"]');
  // Click Menu button to open the drawer
  await page.click('button[title="Menu"]');
  await page.waitForSelector('nav a:has-text("Planos")');

  // Let's click Planos from the drawer to navigate!
  await page.click('nav a:has-text("Planos")');
  await page.waitForURL('**/planos');
  console.log('Navigation via drawer successful!');

  // Take a screenshot of the open drawer on mobile viewport as well
  await page.goto('/tarefas');
  await page.click('button[title="Menu"]');
  await page.waitForSelector('button[title="Fechar"]');
  await page.waitForTimeout(200);
  await expect(page).toHaveScreenshot(['tarefas', 'drawer-vertical.png']);
  console.log('Asserted drawer-vertical.png');
  // Close the drawer
  await page.click('button[title="Fechar"]');

  // Now take the screenshots for each route and layout!
  const routes = [
    'tarefas',
    'tarefas/nova',
    'tarefas/editar/task_0_Comprar_mantimentos_para_a_semana',
    'rotinas',
    'rotinas/nova',
    'planos',
    'planos/novo',
    'planos/editar/plan_0_Lançar_novo_website_pessoal',
    'arquivo',
    'sincronizar'
  ];

  for (const route of routes) {
    console.log(`Taking/asserting screenshots for /${route}...`);
    await page.goto(`/${route}`);
    await page.waitForTimeout(500); // Wait for Elm view transition

    let saveRoute = route;
    if (route.startsWith('tarefas/editar/')) {
      saveRoute = 'tarefas/editar';
    } else if (route.startsWith('planos/editar/')) {
      saveRoute = 'planos/editar';
    }

    for (const [layout, viewport] of Object.entries(viewports)) {
      await page.setViewportSize(viewport);
      await page.waitForTimeout(200); // Allow render adjustment

      const segments = [...saveRoute.split('/'), `${layout}.png`];
      await expect(page).toHaveScreenshot(segments, { fullPage: false });
      console.log(`Asserted ${segments.join('/')}`);
    }
  }

  console.log('All screenshooting successfully finished!');
});
