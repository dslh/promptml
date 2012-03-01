<meta data-script='scripts/test.js' data-onload='testMetaScript'
      data-css='css/test.css' data-class='testMeta' />
<b>H<i>i</i>!</b>
<% unless args.empty? %>
<ul>
  <li>
    <%= args.join("</li><li>") %>
  </li>
</ul>
<% end %>
