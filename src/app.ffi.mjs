export function addGlobalEventListener(name, cb) {
  window.addEventListener(name, cb);
}
