// Controls command history for PrompTML.
// In PrompTML the command history is tied closely to
// the output history, and old commands can be re-executed
// in place, so the new output replaces the old output.
// So, as the user winds back through history the interface
// also winds back through the output window. A special
// interface is required for commands that have been cleared
// from the output.

// Selector for commands in the history.
var COMMAND_HISTORY = '#output .action .command';

// Commands cleared from the output are saved here.
var cleared_history = [''];
var cleared_history_pos = 0;

// As the user winds back through the history, each
// command is replaced by a textbox with the same
// content. We retain the original DOM element in
// case we want to revert changes.
var history_replaced_command = null;

// And of course we keep a reference to the text box
// for editing the current command.
var history_current_editor = null;

// Clear the current history editor and replace it with
// the original command text.
function remove_history_editor() {
  if (history_replaced_command != null) {
    history_current_editor.replaceWith(history_replaced_command);
    history_replaced_command.parent().removeClass('selected');
    history_current_editor = history_replaced_command = null;
  }
}

// Create an editor for a command in the history.
function history_edit_command(command) {
  remove_history_editor();
  
  history_current_editor = $('<form class="command"><input type="text"/></form>');
  $('input',history_current_editor).val(command.text());
  history_replaced_command = command;
  history_replaced_command.parent().addClass('selected');
  history_replaced_command.replaceWith(history_current_editor);
  
  $('input',history_current_editor).focus().keydown(function(event) {
    // Navigate up and down the command history.
    // 38 == UP key
    // 40 == DOWN key
    if (event.which != 38 && event.which != 40) {
      return;
    }
    event.preventDefault();
    
    var current_action = history_current_editor.parent();
    var next_action = $('.command', event.which == 38 ?
          current_action.prev() : current_action.next());
    
    if (next_action.length > 0) {
      history_edit_command(next_action);
    } else {
      if (event.which == 40) {
        $('#input').focus();
      } else {
        // TODO: Implement cleared history interface
      }
    }
  }).keydown(function (event) {
    // Remove the editor
    // 27 ESC key
    if (event.which == 27) {
      event.preventDefault();
      remove_history_editor();
    }
  }).keydown(function (event) {
    // Shift + ENTER sends the command
    // to a new output frame.
    if (event.which == 13 && event.shiftKey) {
      event.preventDefault();
      $('#input').val($(this).val());
      remove_history_editor();
      $('#go').click();
    }
  }).keydown(tab_completion);

  history_current_editor.submit(function(event) {
    event.preventDefault();
    if (working)
      return;
    
    var input = $('input', this);
    var container = $(this).parent();
    var cmd = $.trim(input.val());
    if (cmd.length == 0) return;
    
    if (execute_on_client(cmd,container)) {
      remove_history_editor();
      return;
    }
    
    setWorking(true);
    $.ajax({
      type: 'GET', url: '/cmd?' + escapeCommand(cmd),
      dataType: 'html',
      success: function (response) {
        history_replace_result(container,cmd,response);
        remove_history_editor();
        $('#input').focus();
      },
      error: function (request, message, exception) {
        history_replace_result(container,
            $('<div class="command"><span class="failed">' + cmd + '</span></div>'),
            $('<strong>HTTP ' + request.status
            + ' ' + request.statusText + '</strong>'
            + ' ' + request.responseText));
      },
      complete: function (request, message) {
        setWorking(false);
        last_request = request;
      }
    });
  });
}

function history_replace_result(container, cmd, response) {
  history_replaced_command = $('<div class="command">' + cmd + '</div>');
  $('.response',container).replaceWith(
    $('<div class="response">' + response + '</div>'));
  processMetaTags(container);
}

// Up key from the prompt sends us into the command history.
$('#input').keydown(function(event) {
  // 38 == UP key
  if (event.which != 38) {
    return;
  }
  event.preventDefault();

  history_edit_command($(COMMAND_HISTORY).last());
}).focus(function(event) {
  remove_history_editor();
});
  











