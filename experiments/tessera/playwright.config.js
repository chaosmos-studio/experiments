const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: './tests/browser',
  timeout: 180000,
  workers: 1,
  use: {baseURL: 'http://127.0.0.1:8765', headless: true,
    launchOptions: {args: ['--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader']}},
  webServer: {command: 'python3 -m http.server 8765 --directory build/web', url: 'http://127.0.0.1:8765', reuseExistingServer: false},
  projects: [
    {name: 'desktop', use: {viewport: {width: 1008, height: 1000}}},
    {name: 'mobile', use: {viewport: {width: 390, height: 844}, isMobile: true, hasTouch: true}}
  ]
});
