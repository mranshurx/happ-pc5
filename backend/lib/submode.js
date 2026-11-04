'use strict';

/**
 * Builds the /sub response body for a given feature mode.
 *
 * CALL SITE in server.js, inside GET /sub, replacing the bare `res.send(JSON.stringify(BASE_CONFIG))`:
 *
 *   const submode = require('./lib/submode');
 *   const body = submode.build(BASE_CONFIG, req.query.mode);
 *   res.type('text/plain').send(body);
 */

const GAME_DOMAINS = [
  'regexp:(?i)(freefire|garena|ggblueshark|levelinf|anticheat|ff\\.garena)',
  'regexp:(?i)(dl\\.mobile|mobile\\.garena|prod\\.cdn\\.garena)',
];

const GAME_PORTS = '39000-39999,10000-10999';

function clone(cfg) {
  return JSON.parse(JSON.stringify(cfg));
}

function proxyDomainRule(cfg) {
  return (cfg.routing && cfg.routing.rules || []).find(
    (r) => r.outboundTag === 'proxy' && Array.isArray(r.domain)
  );
}

function proxyPortRule(cfg) {
  return (cfg.routing && cfg.routing.rules || []).find(
    (r) => r.outboundTag === 'proxy' && typeof r.port === 'string'
  );
}

function applyAimbot(cfg) {
  const rule = proxyDomainRule(cfg);
  if (rule) {
    for (const d of GAME_DOMAINS) {
      if (!rule.domain.includes(d)) rule.domain.push(d);
    }
  }
  const port = proxyPortRule(cfg);
  if (port) port.port = GAME_PORTS;

  // Direct CDN exceptions can swallow match traffic; drop them.
  if (cfg.routing && Array.isArray(cfg.routing.rules)) {
    cfg.routing.rules = cfg.routing.rules.filter(
      (r) => !(r.outboundTag === 'direct' && Array.isArray(r.domain))
    );
  }
}

function applyLocation(cfg) {
  const out = (cfg.outbounds || []).find((o) => o.tag === 'proxy');
  if (!out) return;

  const hy = out.streamSettings && out.streamSettings.hysteriaSettings;
  if (hy) hy.mportHopInt = 30;

  if (!cfg.dns) cfg.dns = {};
  cfg.dns.queryStrategy = 'UseIP';
  cfg.dns.disableCache = false;
}

function build(baseConfig, rawMode) {
  const mode = String(rawMode || '').toLowerCase();
  const cfg = clone(baseConfig);

  const aim = mode === 'aimbot' || mode === 'full';
  const low = mode === 'low' || mode === 'full';

  if (aim) applyAimbot(cfg);
  if (low) applyLocation(cfg);

  return JSON.stringify(cfg, null, 2);
}

module.exports = { build, GAME_DOMAINS, GAME_PORTS };
