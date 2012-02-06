var history = [''];
var history_position = 0;

// Add an executed command onto the history stack
function updateHistory(cmd) {
  history.pop(); // Get rid of the blank off the end
  history.push(cmd); // Put the new command on the stack
  history.push(''); // Put a new blank on the end
  history_position = history.length - 1;
}

// Track back and forth through the history stack
$('#input').keydown(function(event) {
  // 38 == UP key
  // 40 == DOWN key
  if (event.which != 38 && event.which != 40) {
    return;
  }

  // We save the current command back into the stack
  // in case it's been modified.
  var p = $('#input');
  var current_cmd = p.val();
  history[history_position] = current_cmd;

  event.preventDefault();
  if (event.which == 38) {
    if (history_position == 0) {
      return;
    }
    p.val(history[--history_position]);
  } else {
    if (history_position == history.length - 1) {
      return;
    }
    p.val(history[++history_position]);
  }

  // Move cursor to the end of the prompt
  p[0].selectionStart = p[0].selectionEnd = p.val().length;
});

// Send the user's command to the server when
// the form is submitted.
$('#prompt').submit(function(event) {
  event.preventDefault();

  var input = $('#input');
  var cmd = $.trim(input.val());
  if (cmd.length == 0) return;

  updateHistory(cmd);

  $.get('/cmd?' + escapeCommand(cmd), function (response) {
    input.val('');
    $('#output').append(
            '<li><div class="command">' + cmd + '</div>' +
            '<div class="response">' + response + '</div></li>');
  });
});

function escapeCommand(cmd) {
  return escape(cmd.replace(/ /g,'+'));
}
