/*!
 * Kairos — widget de chat embebible de Axiia
 * Uso: <script src="https://api.../widget/kairos.js" data-axiia-key="ax_xxx" defer></script>
 *
 * Se monta en un Shadow DOM para quedar aislado del CSS del sitio anfitrión.
 * El "cerebro" vive en el backend (/api/widget/*). Acá solo está la UI.
 */
(function () {
  'use strict';

  // ── Bootstrap ───────────────────────────────────────────────────────────────
  if (window.__axiiaKairosLoaded) return;
  window.__axiiaKairosLoaded = true;

  var script = document.currentScript;
  if (!script) return;
  var SITE_KEY = script.getAttribute('data-axiia-key');
  if (!SITE_KEY) { console.warn('[Kairos] Falta data-axiia-key en el <script>.'); return; }

  // Base de la API = la misma desde donde se sirvió este script.
  var API_BASE = script.src.replace(/\/widget\/kairos\.js.*$/, '');
  var IMG_OPEN   = API_BASE + '/widget/uno.png';  // ojos abiertos
  var IMG_CLOSED = API_BASE + '/widget/dos.png';  // ojos cerrados

  // visitor_id persistente para hilar la conversación del visitante.
  var visitorId;
  try {
    visitorId = localStorage.getItem('axiia_kairos_visitor');
    if (!visitorId) {
      visitorId = 'v-' + Math.random().toString(36).slice(2) + Date.now().toString(36);
      localStorage.setItem('axiia_kairos_visitor', visitorId);
    }
  } catch (e) { visitorId = 'v-' + Date.now().toString(36); }

  // ── Arranque: traer config y montar ──────────────────────────────────────────
  function boot() {
    fetch(API_BASE + '/api/widget/config?key=' + encodeURIComponent(SITE_KEY))
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (cfg) {
        if (!cfg || cfg.enabled === false) return;
        mount(cfg);
      })
      .catch(function () { /* silencioso: no romper el sitio del cliente */ });
  }

  // ── Montaje del widget ────────────────────────────────────────────────────────
  function mount(cfg) {
    var accent   = cfg.accent  || '#0B1D3F';
    var botName  = cfg.bot_name || 'Kairos';
    var greeting = cfg.greeting || ('¡Hola! Soy ' + botName + ' 👋 ¿En qué te puedo ayudar?');
    var quickReplies = Array.isArray(cfg.quick_replies) ? cfg.quick_replies : [];

    var host = document.createElement('div');
    host.id = 'axiia-kairos-host';
    host.style.cssText = 'all:initial;position:fixed;bottom:0;right:0;z-index:2147483000;';
    document.body.appendChild(host);
    var root = host.attachShadow ? host.attachShadow({ mode: 'open' }) : host;

    root.innerHTML = STYLE + TEMPLATE(accent, botName);

    var $ = function (sel) { return root.querySelector(sel); };
    var fab      = $('.k-fab');
    var panel    = $('.k-panel');
    var bubble   = $('.k-bubble');
    var msgs     = $('.k-msgs');
    var quickWrap = $('.k-quick');
    var input    = $('.k-input');
    var sendBtn  = $('.k-send');
    var closeBtn = $('.k-close');
    var imgOpen  = $('.k-eye-open');
    var imgClose = $('.k-eye-closed');

    var open = false;
    var loading = false;
    var firstOpen = true;

    // Precargar imágenes para que el primer parpadeo no parpadee en blanco.
    new Image().src = IMG_OPEN;
    new Image().src = IMG_CLOSED;

    // ── Parpadeo (idéntico a VentaSimple: 3-5s, ojos cerrados 160ms) ───────────
    var blinkTimer;
    function scheduleBlink() {
      clearTimeout(blinkTimer);
      blinkTimer = setTimeout(function () {
        if (open) { scheduleBlink(); return; }
        imgOpen.style.visibility = 'hidden';
        imgClose.style.visibility = 'visible';
        blinkTimer = setTimeout(function () {
          imgOpen.style.visibility = 'visible';
          imgClose.style.visibility = 'hidden';
          scheduleBlink();
        }, 160);
      }, 3000 + Math.random() * 2000);
    }
    scheduleBlink();

    // ── Helpers de UI ──────────────────────────────────────────────────────────
    function scrollDown() { msgs.scrollTop = msgs.scrollHeight; }

    function addMsg(role, text, anchor) {
      var row = document.createElement('div');
      row.className = 'k-row k-' + role;
      if (role === 'bot') {
        var av = document.createElement('img');
        av.className = 'k-av';
        av.src = IMG_OPEN; av.alt = '';
        row.appendChild(av);
      }
      var col = document.createElement('div');
      col.className = 'k-bubcol';
      var b = document.createElement('div');
      b.className = 'k-bub k-bub-' + role;
      b.textContent = text;
      col.appendChild(b);
      // Botón "Llevame ahí" si el agente devolvió un ancla válida de la página.
      if (role === 'bot' && anchor && anchor.id && document.getElementById(anchor.id)) {
        var jump = document.createElement('button');
        jump.className = 'k-anchor-btn';
        jump.textContent = '➜ ' + (anchor.label || 'Llevame ahí');
        jump.addEventListener('click', function () { highlight(anchor.id); });
        col.appendChild(jump);
      }
      row.appendChild(col);
      msgs.appendChild(row);
      scrollDown();
    }

    // Lleva al visitante a la sección de la página y la resalta (baliza), igual
    // que el patrón vs-beacon de Venta Simple. El target vive en el DOM del
    // sitio anfitrión (no en el shadow), por eso usamos document.
    function highlight(id) {
      var el = document.getElementById(id);
      if (!el) return;
      ensureBeaconStyle();
      el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      el.classList.remove('kairos-beacon');
      void el.offsetWidth; // reinicia la animación
      el.classList.add('kairos-beacon');
      setTimeout(function () { el.classList.remove('kairos-beacon'); }, 3600);
    }

    function ensureBeaconStyle() {
      if (document.getElementById('kairos-beacon-style')) return;
      var st = document.createElement('style');
      st.id = 'kairos-beacon-style';
      st.textContent =
        '@keyframes kairos-beacon-pulse{0%{box-shadow:0 0 0 0 ' + accent + '8c}' +
        '70%{box-shadow:0 0 0 12px transparent}100%{box-shadow:0 0 0 0 transparent}}' +
        '.kairos-beacon{animation:kairos-beacon-pulse 1.1s ease-out 3;border-radius:16px;' +
        'scroll-margin-top:90px;scroll-margin-bottom:24px}';
      document.head.appendChild(st);
    }

    // Lee las secciones navegables de la página actual (anclas en vivo).
    function collectAnchors() {
      var out = [], seen = {};
      var nodes = document.querySelectorAll(
        'h1[id],h2[id],h3[id],h4[id],section[id],[data-kairos-anchor]'
      );
      for (var i = 0; i < nodes.length && out.length < 25; i++) {
        var el = nodes[i];
        var id = el.id || el.getAttribute('id');
        if (!id || seen[id]) continue;
        if (el.offsetParent === null) continue; // saltar ocultos
        var label = (el.getAttribute('data-kairos-anchor') || '').trim();
        if (!label) label = (el.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 60);
        if (!label) continue;
        seen[id] = 1;
        out.push({ id: id, label: label });
      }
      return out;
    }

    function setLoading(on) {
      loading = on;
      sendBtn.disabled = on;
      var old = $('.k-typing');
      if (on && !old) {
        var row = document.createElement('div');
        row.className = 'k-row k-bot k-typing';
        row.innerHTML = '<img class="k-av" src="' + IMG_CLOSED + '" alt=""/>' +
          '<div class="k-bub k-bub-bot k-dots"><span></span><span></span><span></span></div>';
        msgs.appendChild(row);
        scrollDown();
      } else if (!on && old) {
        old.remove();
      }
    }

    function renderQuick() {
      quickWrap.innerHTML = '';
      if (!quickReplies.length) return;
      quickReplies.forEach(function (q) {
        var chip = document.createElement('button');
        chip.className = 'k-chip';
        chip.textContent = q;
        chip.addEventListener('click', function () { input.value = q; send(); });
        quickWrap.appendChild(chip);
      });
    }

    function openPanel() {
      open = true;
      panel.style.display = 'flex';
      fab.style.display = 'none';
      bubble.style.display = 'none';
      if (firstOpen) { firstOpen = false; addMsg('bot', greeting); renderQuick(); }
      setTimeout(function () { input.focus(); }, 80);
    }
    function closePanel() {
      open = false;
      panel.style.display = 'none';
      fab.style.display = 'block';
      scheduleBlink();
    }

    // ── Envío de mensajes ──────────────────────────────────────────────────────
    function send() {
      var text = input.value.trim();
      if (!text || loading) return;
      input.value = '';
      quickWrap.innerHTML = '';   // las opciones se ocultan tras el primer mensaje
      addMsg('user', text);
      setLoading(true);
      fetch(API_BASE + '/api/widget/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          key: SITE_KEY, message: text, visitor_id: visitorId,
          page: location.pathname + location.search,
          anchors: collectAnchors(),
        }),
      })
        .then(function (r) { return r.json().catch(function () { return {}; }); })
        .then(function (data) {
          setLoading(false);
          addMsg('bot', (data && data.answer) || 'Disculpá, no pude responder ahora. Probá de nuevo.', data && data.anchor);
        })
        .catch(function () {
          setLoading(false);
          addMsg('bot', 'Hubo un problema de conexión. Intentá de nuevo en un momento.');
        });
    }

    // ── Eventos ────────────────────────────────────────────────────────────────
    fab.addEventListener('click', openPanel);
    bubble.addEventListener('click', openPanel);
    closeBtn.addEventListener('click', closePanel);
    sendBtn.addEventListener('click', send);
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
    });

    // Burbuja proactiva: aparece a los 8s si el chat sigue cerrado.
    setTimeout(function () {
      if (!open) {
        $('.k-bubble-text').textContent = greeting.split('\n')[0];
        bubble.style.display = 'block';
        setTimeout(function () { if (!open) bubble.style.display = 'none'; }, 9000);
      }
    }, 8000);
  }

  // ── Template ──────────────────────────────────────────────────────────────────
  function TEMPLATE(accent, botName) {
    return '' +
    '<div class="k-wrap">' +
      '<div class="k-panel" role="dialog" aria-label="' + botName + '">' +
        '<div class="k-head">' +
          '<div class="k-head-av">' +
            '<img class="k-eye-open" src="' + IMG_OPEN + '" alt="' + botName + '"/>' +
            '<img class="k-eye-closed" src="' + IMG_CLOSED + '" alt=""/>' +
          '</div>' +
          '<div class="k-head-txt">' +
            '<p class="k-name">' + botName + '</p>' +
            '<span class="k-status"><i></i>En línea</span>' +
          '</div>' +
          '<button class="k-close" aria-label="Cerrar">&times;</button>' +
        '</div>' +
        '<div class="k-msgs"></div>' +
        '<div class="k-quick"></div>' +
        '<div class="k-foot">' +
          '<input class="k-input" type="text" placeholder="Escribí tu consulta..." />' +
          '<button class="k-send" aria-label="Enviar">' +
            '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>' +
          '</button>' +
        '</div>' +
      '</div>' +
      '<button class="k-bubble"><span class="k-bubble-text"></span><span class="k-bubble-tag">' + botName + ' · Axiia</span></button>' +
      '<button class="k-fab" aria-label="Abrir ' + botName + '">' +
        '<img class="k-eye-open" src="' + IMG_OPEN + '" alt="' + botName + '"/>' +
        '<img class="k-eye-closed" src="' + IMG_CLOSED + '" alt=""/>' +
      '</button>' +
    '</div>';
  }

  // ── Estilos (con --accent inyectable) ─────────────────────────────────────────
  var STYLE = '<style>' +
    ':host,*{box-sizing:border-box}' +
    '.k-wrap{position:fixed;bottom:24px;right:24px;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;display:flex;flex-direction:column;align-items:flex-end;gap:12px}' +
    /* FAB */
    '.k-fab{width:80px;height:80px;padding:0;border:none;background:transparent;cursor:pointer;position:relative;animation:k-float 5s ease-in-out infinite;display:block}' +
    '.k-fab img,.k-head-av img{position:absolute;top:0;left:0;width:100%;height:100%;object-fit:contain}' +
    '@keyframes k-float{0%,100%{transform:translateY(0)}50%{transform:translateY(-6px)}}' +
    /* Bubble */
    '.k-bubble{display:none;max-width:240px;background:#fff;border:1px solid #e2e0da;border-radius:14px 14px 4px 14px;padding:10px 14px;box-shadow:0 8px 28px rgba(0,0,0,.14);cursor:pointer;text-align:left;animation:k-pop .3s cubic-bezier(.34,1.56,.64,1) both}' +
    '.k-bubble-text{display:block;font-size:13px;font-weight:600;color:#1a1816;line-height:1.45}' +
    '.k-bubble-tag{display:block;font-size:10px;color:#a39d97;margin-top:4px;font-weight:500}' +
    '@keyframes k-pop{from{opacity:0;transform:translateY(6px) scale(.95)}to{opacity:1;transform:none}}' +
    /* Panel */
    '.k-panel{display:none;flex-direction:column;width:min(360px,calc(100vw - 48px));height:min(560px,calc(100vh - 48px));background:#fff;border-radius:22px;overflow:hidden;border:1px solid #d6e0f0;box-shadow:0 28px 80px rgba(11,29,63,.28);animation:k-in .25s cubic-bezier(.34,1.56,.64,1) both}' +
    '@keyframes k-in{from{opacity:0;transform:translateY(16px) scale(.96)}to{opacity:1;transform:none}}' +
    '.k-head{display:flex;align-items:center;gap:10px;padding:14px 16px;background:linear-gradient(135deg,var(--accent) 0%,#1a3460 100%)}' +
    '.k-head-av{position:relative;width:46px;height:46px;flex-shrink:0}' +
    '.k-head-av .k-eye-closed{visibility:hidden}' +
    '.k-name{margin:0;font-size:14px;font-weight:800;color:#fff;letter-spacing:-.01em}' +
    '.k-status{display:flex;align-items:center;gap:5px;font-size:10.5px;color:rgba(255,255,255,.65);font-weight:500;margin-top:2px}' +
    '.k-status i{width:6px;height:6px;border-radius:50%;background:#4ade80;box-shadow:0 0 6px #4ade80}' +
    '.k-head-txt{flex:1}' +
    '.k-close{margin-left:auto;background:rgba(255,255,255,.12);border:none;border-radius:8px;color:#fff;font-size:20px;line-height:1;width:30px;height:30px;cursor:pointer}' +
    /* Messages */
    '.k-msgs{flex:1;overflow-y:auto;padding:16px 14px 10px;background:#f3f6fb;display:flex;flex-direction:column;gap:10px}' +
    '.k-row{display:flex;align-items:flex-end;gap:8px}' +
    '.k-row.k-user{justify-content:flex-end}' +
    '.k-av{width:30px;height:30px;flex-shrink:0;object-fit:contain}' +
    '.k-bubcol{display:flex;flex-direction:column;gap:8px;max-width:78%}' +
    '.k-row.k-user .k-bubcol{align-items:flex-end}' +
    '.k-bub{padding:10px 14px;font-size:13px;line-height:1.55;white-space:pre-wrap;word-wrap:break-word}' +
    '.k-anchor-btn{align-self:flex-start;display:inline-flex;align-items:center;gap:6px;padding:8px 13px;border-radius:10px;background:var(--accent);color:#fff;border:none;cursor:pointer;font-size:12.5px;font-weight:700;font-family:inherit;box-shadow:0 3px 10px rgba(11,29,63,.3)}' +
    '.k-bub-bot{background:#fff;border:1px solid #dde6f3;border-radius:16px 16px 16px 4px;color:#1a1816;box-shadow:0 2px 8px rgba(11,29,63,.07)}' +
    '.k-bub-user{background:var(--accent);color:#fff;border-radius:16px 16px 4px 16px}' +
    '.k-dots{display:flex;gap:4px;align-items:center}' +
    '.k-dots span{width:6px;height:6px;border-radius:50%;background:#94a3b8;display:inline-block;animation:k-dot 1.2s ease-in-out infinite}' +
    '.k-dots span:nth-child(2){animation-delay:.2s}.k-dots span:nth-child(3){animation-delay:.4s}' +
    '@keyframes k-dot{0%,80%,100%{transform:translateY(0);opacity:.35}40%{transform:translateY(-5px);opacity:1}}' +
    /* Quick replies (opciones autogeneradas) */
    '.k-quick{display:flex;flex-wrap:wrap;gap:6px;padding:8px 12px 4px;background:#f3f6fb}' +
    '.k-quick:empty{display:none}' +
    '.k-chip{padding:6px 12px;border-radius:99px;font-size:12px;font-weight:600;background:#fff;border:1.5px solid #c8d8ee;color:var(--accent);cursor:pointer;font-family:inherit}' +
    '.k-chip:hover{background:#eef2fe}' +
    /* Footer */
    '.k-foot{display:flex;gap:8px;align-items:center;padding:10px 12px;border-top:1px solid #e4ecf5;background:#fff}' +
    '.k-input{flex:1;background:#f3f6fb;border:1.5px solid transparent;border-radius:12px;padding:10px 13px;font-size:13px;outline:none;color:#1a1816}' +
    '.k-input:focus{border-color:var(--accent)}' +
    '.k-send{width:38px;height:38px;border-radius:11px;border:none;flex-shrink:0;background:var(--accent);color:#fff;cursor:pointer;display:grid;place-items:center}' +
    '.k-send:disabled{opacity:.5;cursor:default}' +
    '</style>';

  // Inyectar el color de acento como variable CSS en el wrapper.
  var _mount = mount;
  mount = function (cfg) {
    var origStyle = STYLE;
    STYLE = origStyle.replace('<style>', '<style>.k-wrap{--accent:' + (cfg.accent || '#0B1D3F') + '}');
    _mount(cfg);
    STYLE = origStyle;
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
