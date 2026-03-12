#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python - <<'PY'
from pathlib import Path
s=Path('index.html').read_text()
a=s.find('<script>');b=s.rfind('</script>')
Path('/tmp/cinelog.js').write_text(s[a+8:b])
print('extracted_js_bytes', b-a)
PY
node --check /tmp/cinelog.js
rg -n "syncCloudIdentity|cloudPushState|searchConnectPlus|authForgotPassword|connect-mode" index.html > /tmp/cinelog_smoke_rg.txt
echo "smoke_checks_ok"
