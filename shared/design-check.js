// Design check: measures the local app against a `design-checks` block of a
// Lovable design spec (docs/plans/<module>.lovable.md, written by the
// alpha-lovable-reader agent).
//
// Usage: open the screen in Chrome in the state the block's "setup" names,
// replace __CHECKS__ below with the block's JSON (the whole object), and run
// the file's content with the Chrome javascript tool. It returns a JSON
// report: one entry per check with PASS / FAIL / NOT_FOUND / AMBIGUOUS and,
// for FAIL, each property's expected and actual value. It only reads the page.
(() => {
  const SPEC = __CHECKS__;
  const TOL_PX = 0.5; // lengths
  const TOL_RGB = 3; // per colour channel (0-255)
  const TOL_ALPHA = 0.03;

  const norm = (s) => (s || '').replace(/\s+/g, ' ').trim();
  const visible = (el) => el.getClientRects().length > 0;

  function find(f) {
    let cands = [...document.querySelectorAll(f.selector || 'body *')].filter(visible);
    if (f.text != null) {
      const t = norm(f.text);
      cands = cands.filter((el) => norm(el.innerText ?? el.textContent) === t);
      if (!f.selector) {
        // keep the deepest elements holding exactly this text
        cands = cands.filter((el) => ![...el.children].some((c) => norm(c.innerText ?? c.textContent) === t));
      }
    }
    if (f.placeholder != null) cands = cands.filter((el) => el.getAttribute('placeholder') === f.placeholder);
    const count = cands.length;
    let el = cands[f.nth || 0];
    if (el && f.closest) el = el.closest(f.closest);
    return { el, count };
  }

  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 1;
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  function rgba(color) {
    // normalises any CSS colour (rgb, hex, hsl, oklch, named) to [r,g,b,a]
    const m = /^#([0-9a-f]{6})([0-9a-f]{2})?$/i.exec(color.trim());
    if (m) {
      const n = parseInt(m[1], 16);
      return [n >> 16, (n >> 8) & 255, n & 255, m[2] ? parseInt(m[2], 16) / 255 : 1];
    }
    if (color === 'transparent') return [0, 0, 0, 0];
    ctx.clearRect(0, 0, 1, 1);
    ctx.fillStyle = '#000';
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, 1, 1);
    const d = ctx.getImageData(0, 0, 1, 1).data;
    return [d[0], d[1], d[2], d[3] / 255];
  }
  const hex = ([r, g, b, a]) =>
    '#' + [r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('') +
    (a < 1 ? Math.round(a * 255).toString(16).padStart(2, '0') : '');
  const isColorProp = (p) => /color$/.test(p) || p === 'fill' || p === 'stroke';

  function actual(el, prop) {
    const r = el.getBoundingClientRect();
    if (prop === 'width') return `${r.width}px`;
    if (prop === 'height') return `${r.height}px`;
    if (prop === 'text') return norm(el.innerText ?? el.textContent);
    return getComputedStyle(el).getPropertyValue(prop);
  }

  function same(prop, exp, act) {
    exp = String(exp).trim();
    act = String(act).trim();
    if (isColorProp(prop)) {
      const a = rgba(exp), b = rgba(act);
      if (a[3] === 0 && b[3] === 0) return [true, hex(b)];
      const ok = a.slice(0, 3).every((v, i) => Math.abs(v - b[i]) <= TOL_RGB) && Math.abs(a[3] - b[3]) <= TOL_ALPHA;
      return [ok, hex(b)];
    }
    const px = /^(-?[\d.]+)px$/;
    if (px.test(exp) && px.test(act)) {
      return [Math.abs(parseFloat(exp) - parseFloat(act)) <= TOL_PX, `${Math.round(parseFloat(act) * 100) / 100}px`];
    }
    if (prop === 'font-family') {
      const first = (s) => s.split(',')[0].replace(/["']/g, '').trim().toLowerCase();
      return [first(exp) === first(act), act];
    }
    return [exp.toLowerCase() === act.toLowerCase(), act];
  }

  const found = {};
  const results = SPEC.checks.map((c) => {
    const { el, count } = find(c.find);
    if (!el) return { id: c.id, status: 'NOT_FOUND', find: c.find };
    found[c.id] = el;
    const diffs = [];
    for (const [prop, exp] of Object.entries(c.expect || {})) {
      const [ok, act] = same(prop, exp, actual(el, prop));
      if (!ok) diffs.push({ prop, expected: exp, actual: act });
    }
    const res = { id: c.id, status: diffs.length ? 'FAIL' : 'PASS', diffs };
    if (count > 1 && c.find.nth == null) res.note = `AMBIGUOUS: ${count} matches, measured the first`;
    return res;
  });

  // relative position checks, after every element is found
  const rel = {
    rightOf: (a, b) => a.left >= b.right - 1,
    leftOf: (a, b) => a.right <= b.left + 1,
    below: (a, b) => a.top >= b.bottom - 1,
    above: (a, b) => a.bottom <= b.top + 1,
  };
  SPEC.checks.forEach((c, i) => {
    for (const key of Object.keys(rel)) {
      if (!c[key] || !found[c.id]) continue;
      const other = found[c[key]];
      const r = results[i];
      if (!other) { r.diffs.push({ prop: key, expected: c[key], actual: 'other element not found' }); r.status = 'FAIL'; continue; }
      if (!rel[key](found[c.id].getBoundingClientRect(), other.getBoundingClientRect())) {
        r.diffs.push({ prop: key, expected: c[key], actual: 'not positioned so' });
        r.status = 'FAIL';
      }
    }
  });

  const count = (s) => results.filter((r) => r.status === s).length;
  return JSON.stringify({
    screen: SPEC.screen,
    url: location.href,
    viewport: `${innerWidth}x${innerHeight}`,
    summary: { pass: count('PASS'), fail: count('FAIL'), notFound: count('NOT_FOUND') },
    results: results.filter((r) => r.status !== 'PASS').concat(results.filter((r) => r.status === 'PASS').map((r) => ({ id: r.id, status: 'PASS', note: r.note }))),
  }, null, 2);
})();
