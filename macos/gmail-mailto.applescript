-- Gmail Mailto: hands mailto: links to Gmail's compose window in Chrome.
-- install.sh compiles this into ~/Applications/Gmail Mailto.app and, the
-- first time, makes it the default handler for mailto:. Edit here, not there.

on open location theURL
	-- Gmail wants the whole mailto: URL, percent-encoded, in its url= parameter.
	set enc to do shell script "printf %s " & quoted form of theURL & " | /usr/bin/perl -pe 's/([^A-Za-z0-9._~-])/sprintf(\"%%%02X\", ord($1))/seg'"
	do shell script "open -a 'Google Chrome' " & quoted form of ("https://mail.google.com/mail/?extsrc=mailto&url=" & enc)
end open location

-- Opened directly rather than through a link: just show Gmail.
on run
	do shell script "open -a 'Google Chrome' 'https://mail.google.com/'"
end run
