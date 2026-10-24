'use strict';
// C-2 core logic (pure function, no Spectral dependency so it can be unit-tested offline).
// Rule (Identity Contract v1 §5/§8): every operation that ENFORCES auth must declare BOTH 401 and 403.
// Decisions (proposals, user to confirm):
//  - effective security = operation.security if the key exists (even []), else document-level security
//  - "enforced" = non-empty array AND no empty requirement object {} (an {} entry means auth is optional)
//  - only literal '401' and '403' count (not '4XX', not 'default'): contract says "no exceptions"
const METHODS = ['get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace'];

function isEnforced(security) {
  if (!Array.isArray(security) || security.length === 0) return false;
  return !security.some((req) => req && typeof req === 'object' && Object.keys(req).length === 0);
}

function checkAuthResponses(doc) {
  const out = [];
  if (!doc || typeof doc !== 'object' || !doc.paths || typeof doc.paths !== 'object') return out;
  for (const [p, item] of Object.entries(doc.paths)) {
    if (!item || typeof item !== 'object') continue;
    for (const m of METHODS) {
      const op = item[m];
      if (!op || typeof op !== 'object') continue;
      const security = Object.prototype.hasOwnProperty.call(op, 'security') ? op.security : doc.security;
      if (!isEnforced(security)) continue;
      const responses = op.responses && typeof op.responses === 'object' ? op.responses : {};
      const missing = ['401', '403'].filter((c) => !Object.prototype.hasOwnProperty.call(responses, c));
      if (missing.length) {
        out.push({
          path: ['paths', p, m, 'responses'],
          message: `${m.toUpperCase()} ${p} enforces auth but does not declare: ${missing.join(', ')}`,
        });
      }
    }
  }
  return out;
}


// Spectral custom function (CommonJS). Use with `given: "$"` so the input is the whole document.
module.exports = function cloudforgeAuthResponses(doc) {
  return checkAuthResponses(doc);
};
module.exports.check = checkAuthResponses;
