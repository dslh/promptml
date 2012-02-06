$('#prompt').submit(function(event) {
  event.preventDefault();

  var input = $('#input');
  var cmd = $.trim(input.val());
  if (cmd.length == 0) return;

  $.get('/cmd?' + escapeCommand(cmd), function (response) {
    $('#output').append(
            '<li><div class="command">' + cmd + '</div>' +
            '<div class="response">' + response + '</div></li>');
  });
});

function escapeCommand(cmd) {
  return escape(cmd.replace(/ /g,'+'));
}
