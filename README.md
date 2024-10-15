# A website to display pisciners' (potential students) faces and their nicknames

This code has been useful to me being a volunteer in school 42, since this information has not been easily available to me.

`downloader` folder contains various scripts to get the list of pisciners (their nicknames) and their photos. It is currently not "nixified".

`server` folder contains a simple TLS capable HTTP server. It has a `http-prefix` option to make it visible only to ones who know the path.

`flake.nix` has a NixOS module to run the server.

Technologies involved: Nix, Makefile, Bash, Go, JQ, Pandoc, HTML, cURL.

## License: MIT
