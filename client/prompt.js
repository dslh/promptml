$('#prompt').submit(function(event) {
  event.preventDefault();

  var input = $('#input');
  var cmd = input.val().replace(/ /g,'+');
  input.val('');
  $.get('/cmd?' + escape(cmd), function (data) {
    $('#output').append('<li>' + data + '</li>');
  });
});