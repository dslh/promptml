// A history of commands sent to the server,
// oldest first.
var history = [''];
var history_position = 0;

// True if there is an ajax request en route
// to the server. The prompt only allows one
// request at a time.
var working = false;

// Debugging variable, remove at some point maybe
var last_request = null;

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
  if (working)
    return;

  var input = $('#input');
  var cmd = $.trim(input.val());
  if (cmd.length == 0) return;

  updateHistory(cmd);

  working = true;
  $.ajax({
    type: 'GET', url: '/cmd?' + escapeCommand(cmd),
    dataType: 'html',
    success: function (response) {
      appendResult(cmd, response);
    },
    error: function (request, message, exception) {
      appendResult(cmd,
        '<strong>HTTP ' + request.status
        + ' ' + request.statusText + '</strong>'
        + ' ' + request.responseText);
    },
    complete: function (request, message) {
      input.val('');
      working = false;
      last_request = request;
    }
  });
});

// Add the user's command and the response
// returned from the server to the output list
function appendResult(command,response) {
  $('#output').append(
        '<li><div class="command">' + command + '</div>' +
        '<div class="response">' + response + '</div></li>'
  );
}

// URI encode the user's command
function escapeCommand(cmd) {
  return escape(cmd.replace(/ /g,'+'));
}

// Style-related. Ensure the output window fills the browser,
// save for a space at the bottom for the prompt.
function setOutputSize() {
  $('#output_scroll').css('height',
    ($('body').innerHeight() - $('#prompt').outerHeight())
      + 'px');
}
$(setOutputSize);
$(function() { $('#input').focus() });
$(window).resize(setOutputSize);
