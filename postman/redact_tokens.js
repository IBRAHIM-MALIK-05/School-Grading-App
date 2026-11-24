// postman/redact_tokens.js
// Removes every JWT (login token) from a Newman HTML report before it is kept / committed.
// Tokens appear in the login RESPONSE bodies (and would appear in Authorization headers,
// which the run scripts already leave out with --reporter-htmlextra-omitHeaders).
//
//   node redact_tokens.js reports\azure_test_report.html
//
// Exit code 1 if a token could still be found afterwards.

const fs = require("fs");

// header.payload.signature, each part base64url; JWTs always start with "eyJ" ( = '{"' )
const JWT = /eyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g;
const LEFTOVER = /eyJ[A-Za-z0-9_-]{10,}/g;

let failed = false;
for (const file of process.argv.slice(2)) {
  const html = fs.readFileSync(file, "utf8");
  const found = (html.match(JWT) || []).length;
  const clean = html.replace(JWT, "[JWT redacted]");
  fs.writeFileSync(file, clean, "utf8");
  const left = (clean.match(LEFTOVER) || []).length;
  console.log(`${file}: ${found} token(s) redacted, ${left} left`);
  if (left > 0) failed = true;
}
process.exit(failed ? 1 : 0);
