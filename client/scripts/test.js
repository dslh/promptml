function testMetaScript(dom) {
  function fadeOut(dom) {
    dom.animate({opacity: 0.5}, 2000, function() {fadeIn(dom)});
  }

  function fadeIn(dom) {
    dom.animate({opacity: 1.0}, 2000, function() {fadeOut(dom)});
  }

  fadeOut(dom);
}
