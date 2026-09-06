const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './testes',
  testMatch: 'páginas.js',
  snapshotPathTemplate: '{testDir}/páginas/{arg}{ext}',
  timeout: 60000,
  expect: {
    timeout: 5000
  },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1, // Let's use 1 worker to ensure order of execution and no collisions
  reporter: 'list',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { 
        ...devices['Desktop Chrome'],
        launchOptions: {
          executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH
        }
      },
    },
  ],
  webServer: {
    command: 'npx serve -s alvo -l 3000',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
