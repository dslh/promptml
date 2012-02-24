function testMetaScript(dom) {
  function fadeOut(dom) {
    dom.animate({opacity: 0.25}, 1000, function() {fadeIn(dom)});
  }

  function fadeIn(dom) {
    dom.animate({opacity: 1.0}, 1000, function() {fadeOut(dom)});
  }

  fadeOut(dom);
}
