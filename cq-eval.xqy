(:
 : Client Query Application
 :
 : evaluation module
 :
 : Copyright (c) 2002, 2003, 2004 Mark Logic Corporation. All rights reserved.
 :)

define variable $g-mime-type {
  xdmp:get-request-field("cq_mimeType", "text/xml")
}

define function display-xml($x) {
  if (count($x) = 1
    and ($x instance of element() or $x instance of document-node())
  ) then $x
  else element results {
    attribute warning {
      if (empty($x)) then "empty list"
      else if (count($x) = 1) then "non-element node"
      else "more than one node"
    },
    for $i in $x
    return
      if ($i instance of document-node())
      then $i/*
      else $i
  }
}

define function display-html($x) as element() {
<html xmlns="http://www.w3.org/1999/xhtml">
  <body bgcolor="white">
    <table>
      <tr valign="top"><td>
{
  for $i in $x
  return
    if ($i instance of document-node())
    then $i/*
    else $i
}
      </td></tr>
    </table>
  </body>
</html>
}

define function display-text($x) { $x }

define function error-xml($ex as element()) as element() {
  <EXCEPTION xml:space="preserve">{
    <MESSAGE>{
    if (exists($ex//err:format-string/text()))
    then $ex//err:format-string/text()
    else $ex//err:code/text(),
    " at line ", ($ex//err:line)[1]/text()
    }</MESSAGE>,
    (:
      if the stack trace has more than one frame,
      display the entire stack trace
     :)
    if (count($ex/err:stack/err:frame) gt 1)
    then $ex/err:stack
    else ()
  }</EXCEPTION>
}

define function error-html($ex as element()) as element() {
  <b xmlns="http://www.w3.org/1999/xhtml">{
    if (exists($ex//err:format-string/text()))
    then $ex//err:format-string/text()
    else $ex//err:code/text(),
    " at line ", ($ex//err:line)[1]/text(),
    <br/>,
    if (count($ex/err:stack/err:frame) gt 1)
    then (
      "Stack trace:", <br/>,
      for $f in $ex/err:stack/err:frame
      return (
        if (empty($f/err:operation))
        then "(entry-point or unknown function)"
        else $f/err:operation/text(),
        " at ", $f/err:uri/text(),
        " line ", $f/err:line/text(), <br/>
      )
    )
    else (),
    <br/>
    (:,xdmp:quote($ex/err:stack):)
  }</b>
}

define function error-text($ex as element()) as xs:string {
  let $nl := codepoints-to-string((12))
  return string-join((
    if (exists($ex//err:format-string/text()))
    then $ex//err:format-string/text()
    else $ex//err:code/text(),
    " at line ", ($ex//err:line)[1]/text(),
    $nl,
    if (count($ex/err:stack/err:frame) gt 1)
    then (
      "Stack trace:", $nl,
      for $f in $ex/err:stack/err:frame
      return (
        if (empty($f/err:operation))
        then "(entry-point or unknown function)"
        else $f/err:operation/text(),
        " at ", $f/err:uri/text(),
        " line ", $f/err:line/text(), $nl
      )
    )
    else (),
    $nl
    (:,xdmp:quote($ex/err:stack):)
  ), "")
}

xdmp:set-response-content-type(concat($g-mime-type, "; charset=utf-8")),

try {
  let $x := xdmp:eval(xdmp:get-request-field("queryInput"))
  return
    if ($g-mime-type = "text/xml")
    then display-xml($x)
    else if ($g-mime-type = "text/html")
    then display-html($x)
    else display-text($x)
} catch ($ex) {
  if ($g-mime-type = "text/xml")
  then error-xml($ex)
  else if ($g-mime-type = "text/html")
  then error-html($ex)
  else error-text($ex)
}

(: cq-eval.xqy :)
