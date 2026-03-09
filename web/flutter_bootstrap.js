{{flutter_js}}
{{flutter_build_config}}

window.dispatchEvent(new CustomEvent('app-shell-status', { detail: 'Downloading app…' }));

const isLocalhost =
  window.location.hostname === 'localhost' ||
  window.location.hostname === '127.0.0.1' ||
  window.location.hostname === '[::1]';

const canUseServiceWorker =
  'serviceWorker' in navigator && (window.isSecureContext || isLocalhost);

if (!canUseServiceWorker) {
  console.info('Service worker disabled: insecure context (HTTPS/localhost required).');
}

const loadConfig = {
  onEntrypointLoaded: async (engineInitializer) => {
    window.dispatchEvent(new CustomEvent('app-shell-status', { detail: 'Initializing engine…' }));
    const appRunner = await engineInitializer.initializeEngine();
    window.dispatchEvent(new CustomEvent('app-shell-status', { detail: 'Starting app…' }));
    await appRunner.runApp();
    window.dispatchEvent(new Event('app-started'));
  },
};

if (canUseServiceWorker) {
  loadConfig.serviceWorkerSettings = {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  };
}

_flutter.loader.load(loadConfig);
