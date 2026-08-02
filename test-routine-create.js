const { chromium } = require('playwright');
const { createServer } = require('http');
const handler = require('serve-handler');

// Quick local server
const server = createServer((request, response) => {
  return handler(request, response, {
    public: 'alvo',
    rewrites: [
      { source: '**', destination: '/index.html' }
    ]
  });
});

server.listen(3000, async () => {
  console.log('Running test...');
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto('http://localhost:3000/rotinas');
  await page.waitForTimeout(500); // let db load
  await page.click('#btn-nova-rotina');
  await page.fill('#new-routine-title', 'Rotina Teste Semanal');
  await page.selectOption('#new-routine-recurrence', 'Semanal');

  // Choose yesterday
  const today = new Date();
  today.setDate(today.getDate() - 1); // Yesterday
  const weekdays = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];
  const yestStr = weekdays[today.getDay()];

  // Click yesterday's button
  await page.click(`button:has-text("${yestStr}")`);

  // Click submit
  await page.click('button[type="submit"]');
  await page.waitForTimeout(500);

  // Check if a task was created today for the routine created just now!
  await page.goto('http://localhost:3000/tarefas');
  await page.waitForTimeout(500);
  const taskTitle = await page.textContent('body');
  if (taskTitle.includes('Rotina Teste Semanal')) {
    console.log('SUCCESS: Task was successfully created on routine creation when picking yesterday!');
  } else {
    console.log('FAILED: Task was NOT created on routine creation!');
  }

  await browser.close();
  server.close();
});
