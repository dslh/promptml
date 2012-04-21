<%
  wd = Paths.real_path cwd
  wd.gsub! /\//,'\\'
  if args[0] == '-h'
    %><%=`cd #{wd} && #{args[1..-1].join ' '}`%><%
  else
%>
<pre>
<%==`cd #{wd} && #{args.join ' '}`%>
</pre>
<%
  end
%>


