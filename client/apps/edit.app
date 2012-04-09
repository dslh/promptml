<%
  unless args.length == 1
    %><pre> 
    Usage: <%=cmd%> file
    Opens an editor for the given file.
    </pre><%
    return
  end

  file = Paths.make_absolute args[0], cwd
  if Paths.directory? file
    %>
    <meta data-class="error" />
    <code><%=file%></code> is a directory.
    <%
    return
  end

  ext = File.extname(file).downcase
  mode = case ext
  when '.js'
    'javascript'
  when '.css'
    'css'
  when '.rb'
    'ruby'
  when '.erb', '.app'
    'application/x-ejs'
  when '.html', '.htm'
    'htmlmixed'
  else
    'htmlmixed'
  end
%>
<meta data-onload='makeCodeMirrorEditor' data-class='CodeMirror-action'
  data-mode='<%=mode%>' data-path='<%=file%>' />
<form class='CodeMirror-form'><textarea>
<% if Paths.exist? file %>
<%== File.read Paths.real_path(file) %>
<% end %>
</textarea></form>
<button class='CodeMirror-save' disabled='true'>saved</button>
