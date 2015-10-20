#!/bin/sh

escape_html() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; '"s/'/\&#39;/g"
}

cat <<EOF
Content-Type: text/html

<html>
<title>Hello</title>
<body>
<h4>$(escape_html "$(/cfg/hello-world.sh)")</h4>
<div style="white-space: pre">
You are $(escape_html "$REMOTE_ADDR").

My uname is $(escape_html "$(uname -a)").
I'm running $(escape_html "$SERVER_SOFTWARE").
</div>
</body></html>
EOF
