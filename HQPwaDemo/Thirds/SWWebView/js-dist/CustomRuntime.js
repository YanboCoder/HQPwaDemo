(() => {
  const serviceWorker = {
    register: (scriptURL, options = {}) => {
      let modifiedScriptURL = new URL(scriptURL, location.href);
      let modifiedOptions = undefined;
      if (options.scope) {
        modifiedOptions = new URL(location.href).origin + options.scope
      }
      sendDataToNative('navigator.serviceWorker.register', {
        scriptURL: modifiedScriptURL,
        options: modifiedOptions
      });

      // TODO: 需要返回一个 serviceWorkerRegistration 实例对象
      const serviceWorkerRegistration = {}
      return Promise.resolve(serviceWorkerRegistration);
    },
  }

  const sendDataToNative = (eventName, eventData) => {
    try {
      const args = { eventName, eventData: JSON.parse(JSON.stringify(eventData)) };
      window.webkit.messageHandlers.foo.postMessage(args);
    } catch (error) { /* Ignore catch statement */ }
  };

  if (!window.navigator.serviceWorker) {
    window.navigator.serviceWorker = serviceWorker;
  }
})();



