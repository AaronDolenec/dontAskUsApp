{{flutter_js}}
{{flutter_build_config}}

window.dispatchEvent(new CustomEvent('app-shell-status', { detail: 'Downloading app…' }));

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async (engineInitializer) => {
    window.dispatchEvent(new CustomEvent('app-shell-status', { detail: 'Initializing engine…' }));
    const appRunner = await engineInitializer.initializeEngine();
    window.dispatchEvent(new CustomEvent('app-shell-status', { detail: 'Starting app…' }));
    await appRunner.runApp();
    window.dispatchEvent(new Event('app-started'));
  },
});
