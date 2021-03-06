// Commands that are intercepted by the client
// and executed locally. Don't forget to add
// these to the server side tab completion list.
// We use the cmd_ prefix to avoid collisions with
// other object properties.
var client_commands = {
  cmd_clear: function() {
    $(COMMAND_HISTORY).each(function() {
      cleared_history.push($(this).text());
    });
    $("#output").html('')
  }
}
var command_matcher = /^\s*(\S+)(\s.*$)?/
function execute_on_client(command,container) {
  var match = command_matcher.exec(command);
  if (!match) return false;

  var func = client_commands['cmd_' + match[1]];
  if (!func) return false;

  func(match[2]);
  return true;
}

// Enters the given command into the prompt
// and executes it.
function promptml(cmd) {
  $('#input').val(cmd);
  $('#prompt').submit();
}

// True if there is an ajax request en route
// to the server. The prompt only allows one
// request at a time.
var working = false;

// Debugging variable, remove at some point maybe
var last_request = null;

// Tab completion service
$('#input').keydown(tab_completion);

// Should be passed as a keydown handler for
// text inputs requiring text completion.
function tab_completion() {
  if (event.which != 9 || event.shiftKey) {
    return;
  }
  event.preventDefault();

  // Pull from the prompt the root that should be
  // sent to the server for tab completion. This is
  // the portion of the prompt between the cursor and
  // the preceding space.
  var input = this;
  var root = input.value.substring(0, input.selectionStart);
  var start = root.lastIndexOf(' ') + 1;
  root = root.substring(start, root.length);
  var type = start == 0 ? 'cmd' : 'file';

  setWorking(true);
  $.ajax({
    type: 'GET', url: '/tab?' + type + '&' + escape(root),
    dataType: 'html',
    success: function (response) {
      var matches = eval(response);
      var before = input.value.substring(0, start);
      var after = input.value.substring(input.selectionEnd,
                                        input.value.length);
      if (matches === null ||
          matches.constructor.name === "Array") {
        affix_tab_completion_matches(input, root, type, matches);
      } else {
        input.value = before + matches + after;
        input.selectionStart = input.selectionEnd = before.length + matches.length;
      }
    },
    complete: function (request, message) {
      setWorking(false);
    }
  });
}

// Adds a popup to a text box displaying a list of
// autocomplete options, after the user has hit the tab
// key.
function affix_tab_completion_matches(input, root, type, matches) {
  input = $(input);
  var html;
  if (matches === null) {
    html = 'No ' + (type === 'cmd' ? 'commands' : 'files') +
      ' match <b>' + root + '</b>.';
  } else {
    html = matches.join('<br/>');
  }
  
  var dom = $('<div class="tab_completion_options">' + html + '</div>');
  var container = input.offsetParent();
  container.append(dom);
  var top;
  if (dom.height() > container.offset().top + input.position().top)
    top = input.position().top + input.height() + 10;
  else
    top = input.position().top - dom.height() - 10;
  dom.css({
    'left' : (input.position().left + 10) + 'px',
    'top' : top + 'px'
  });
  var remove = function() {
    dom.detach();
    input.off('.tab_completion');
  };
  input.on('blur.tab_completion', remove)
       .on('keydown.tab_completion', remove);
}

// Send the user's command to the server when
// the form is submitted.
$('#prompt').submit(function(event) {
  event.preventDefault();
  if (working)
    return;

  var input = $('#input');
  var cmd = $.trim(input.val());
  if (cmd.length == 0) return;

  if (execute_on_client(cmd)) {
    input.val('');
    return;
  }

  setWorking(true);
  $.ajax({
    type: 'GET', url: '/cmd?' + escapeCommand(cmd),
    dataType: 'html',
    success: function (response) {
      input.val('');
      appendResult(cmd, response);
    },
    error: function (request, message, exception) {
      appendResult(
        '<span class="failed">' + cmd + '</span>',
        '<strong>HTTP ' + request.status
        + ' ' + request.statusText + '</strong>'
        + ' ' + request.responseText);
    },
    complete: function (request, message) {
      setWorking(false);
      last_request = request;
      input.focus();
    }
  });
});

// When the prompt is 'working' it is disabled
function setWorking(w) {
  working = w;
  $('#input, #output .action form.command input')[0].disabled = working;
  if (working) {
    $('#go').html('<img src="images/loading.gif"/>');
  } else {
    $('#go').text('go');
  }
}

// Add the user's command and the response
// returned from the server to the output list
function appendResult(command,response) {
  var output = $('#output');
  var scroll = $('#output_scroll');
  var dom = $(
        '<li class="action"><div class="command">' + command + '</div>' +
        '<div class="response">' + response + '</div></li>'
  );
  output.append(dom);
  processMetaTags(dom);
  dom.hide().fadeIn(700);
  
  if (output.outerHeight() > scroll.innerHeight()) {
    scroll.animate({ scrollTop:
      (output.outerHeight() - scroll.innerHeight() + 32) },
      750);
  }
}

// URI encode the user's command
function escapeCommand(cmd) {
  return escape(cmd.replace(/ /g,'+'));
}

function getFunction(name) {
  var func = window[name];
  if (func && func.constructor.name == 'Function')
    return func;
  else
    return null;
}


function processMetaTags(dom) {
  var data = $('meta',dom).data();
  if (!data)
    return;

  if (data.class)
    dom.addClass(data.class);

  if (data.alert)
    window.alert(data.alert);

  if (data.script) {
    $.getScript(data.script)
      .done(function(script, textStatus) {
        var onload = getFunction(data.onload);
        if (onload)
          onload(dom,data);
      })
      .fail(function(jqxhr, settings, exception) {
        appendResult('Warning','Failed to retrieve script <code>' +
               data.script + '</code>');
      });
  } else {
    var onload = getFunction(data.onload);
    if (onload)
      onload(dom,data);
  }

  if (data.css) {
    getCss(data.css);
  }
}

function makeCodeMirrorEditor(dom,data) {
  var textarea = $('textarea',dom)[0]
  var button = $('button.CodeMirror-save',dom)
  var editor = CodeMirror(function(elt) {
    textarea.parentNode.replaceChild(elt, textarea);
  }, {
    value: textarea.value,
    mode: data.mode,
    lineNumbers: true,
    onChange: function(editor,changes) {
      button.text('save');
      button.prop('disabled',null);
    }
  });
  $('button',dom).click(function() {
    $.ajax({
      url: '/client' + data.path,
      type: 'put',
      data: editor.getValue(),
      success: function() {
        button.text('saved');
        button.prop('disabled','true');
      },
      error: function() {
        button.text('not saved!');
      }
    });
  });
}

// Loads the specified css file and embeds it
// into the page. Won't load the same file twice
// and uses a special method for IE.
var gotCss = {}
function getCss(url) {
  if (gotCss['css_' + url]) return;

  if (document.createStyleSheet) {
    gotCss['css_' + url] = true;
    try {
      document.createStyleSheet(url);
    } catch (e) {
      gotCss['css_' + url] = false;
    }
  } else {
    $.get(url)
      .done(function(css) {
        $('<style type="text/css"></style>')
          .html(css).appendTo("head");
        gotCss['css_' + url] = true;
      });
  }
}

// Style-related. Ensure the output window fills the browser,
// save for a space at the bottom for the prompt.
function setOutputSize() {
  $('#output_scroll').css('height',
    ($('body').innerHeight() - $('#prompt').outerHeight())
      + 'px');
}
$(setOutputSize);
$(window).resize(setOutputSize);

$(function() { $('#input').focus() });

// Pull the current working directory from browser cookies
// and use it as the prompt. The prompt floats over top
// of the input box so we need to adjust the input's
// padding property to allow space for it.
function displayCwd() {
  var newPrompt = $.cookie('CWD') + '>';
  var div = $('#cwd');
  if (div.text() != newPrompt) {
    div.text(newPrompt);
    $('#input').css('paddingLeft',(div.outerWidth() + 5) + 'px');
  }
}
$(displayCwd);
$('#cwd').ajaxComplete(displayCwd);
