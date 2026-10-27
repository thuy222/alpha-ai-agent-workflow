#!/bin/sh
# Copy an HTML file to the macOS clipboard as rich text (public.html) plus a
# plain-text fallback, so Slack keeps bold labels and bullets.
# Usage: copy-html.sh <absolute path to report.html>
set -eu
[ -f "${1:-}" ] || { echo "usage: $0 <report.html>" >&2; exit 1; }
osascript -l JavaScript - "$1" <<'JS'
ObjC.import("AppKit");
function run(argv) {
  var h = $.NSString.stringWithContentsOfFileEncodingError(argv[0], $.NSUTF8StringEncoding, null);
  var pb = $.NSPasteboard.generalPasteboard;
  pb.clearContents;
  pb.setStringForType(h, "public.html");
  pb.setStringForType($(h.js.replace(/<li>/g, "• ").replace(/<\/(li|p)>/g, "\n")
    .replace(/<[^>]+>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")), "public.utf8-plain-text");
  return "copied";
}
JS
