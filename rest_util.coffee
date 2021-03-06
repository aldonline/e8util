$ = require 'jquery'

# takes a JSON structure
# that conforms to the E8 REST protocol
# and generates clickable HTML

exports.json_to_html = json_to_html = ( json ) ->
  render_node json, $container = $ '<div>'
  $container.html()

render_node = ( node, $parent ) ->
  if node instanceof Array
    $parent.append $('<span>').text '['
    $parent.append $ol = $ '<ol>'
    for item in node
      render_node item, $ol
    $parent.append $('<span>').text ']'
  else if typeof node is 'object'
    $parent.append $('<span>').text '{'
    $parent.append $ul = $ '<ul>'
    for own k, v of node
      $ul.append $li = $('<li>').append $('<span>').text k + ': '
      if k in [ 'url', 'link', 'action_url', 'img', 'activation_link', 'icon' ] or ( k is 'children' and typeof v is 'string' )
        $li.append $('<a>').text(v).attr href: v
      else if k is 'label'
        $li.append $('<strong>').text(v)
      else
        render_node v, $li
    $parent.append $('<span>').text '}'
  else
    $parent.append $('<span>').text node.toString()

r = /[']/gi
exports.generate_jsonp = generate_jsonp = ( req, obj ) ->
  if ( cb = req.query.callback )?
    str = JSON.stringify obj
    str = str.replace r, "\\'"
    "#{cb}('#{str}')"
  else
    JSON.stringify obj

exports.send_json_or_html = send_json_or_html = ( req, res, result_obj, try_to_send_html = false ) ->
  send_html = false
  if try_to_send_html
    try
      send_html = req.headers.accept.indexOf('text/html') isnt -1
  unless send_html
    res.send generate_jsonp(req, result_obj), { 'Content-Type': 'text/plain' }, 200
  else
    body = json_to_html result_obj
    res.send """<html>
        <style>
        * {
            font-family: "Courier New" , Courier , monospace ;
            font-size: 11px;
          }
        li {
          list-style: none;
        }
        </style>
        <body>#{body}</body>
      </html>
    """

exports.standard_result_middleware = ( try_to_send_html = false) -> ( req, res, next ) ->
  # 1. Build result object according to protocol
  ok = no
  result_obj = {}
  if req.__result?
    ok = yes
    result_obj.result = req.__result
  if req.__error?
    ok = yes
    result_obj.error = req.__error
  
  if ok
    # 2. Encode and send the result
    send_json_or_html req, res, result_obj, try_to_send_html
  else
    next() # if there is no __result or __error, we pass
