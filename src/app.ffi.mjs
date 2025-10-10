export function addGlobalEventListener(name, cb) {
  window.addEventListener(name, cb);
}

var counter = 0;

export function globalId() {
  return counter++;
}
