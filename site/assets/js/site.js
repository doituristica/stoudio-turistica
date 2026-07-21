/* ==========================================================================
   UP FTŠ sTOUdio Turistica — skupna logika / shared logic
   Dvojezično (sl + en). Brez odvisnosti, brez build koraka.
   Bilingual (sl + en). No dependencies, no build step.
   ========================================================================== */
(function () {
  'use strict';

  // Jezik pove <html lang>. Angleške strani živijo v /en/.
  var LANG = document.documentElement.getAttribute('lang') === 'en' ? 'en' : 'sl';

  /* Ključ strani (data-page) je enak v obeh jezikih — razlikujejo se le imena datotek. */
  var PAGES = {
    home:      { sl: 'index.html',     en: 'index.html' },
    pogovori:  { sl: 'pogovori.html',  en: 'talks.html' },
    zmenki:    { sl: 'zmenki.html',    en: 'dates.html' },
    izleti:    { sl: 'izleti.html',    en: 'trips.html' },
    projekti:  { sl: 'projekti.html',  en: 'projects.html' },
    vikendi:   { sl: 'vikendi.html',   en: 'weekends.html' },
    startaupi: { sl: 'startaupi.html', en: 'startups.html' },
    arhiv:     { sl: 'arhiv.html',     en: 'archive.html' },
    'o-nas':   { sl: 'o-nas.html',     en: 'about.html' },
    aktivnost: { sl: 'aktivnost.html', en: 'activity.html' }
  };

  /* Vrstni red kategorij v navigaciji; ključ ustreza polju `category` v JSON-u. */
  var CATEGORY_ORDER = ['pogovori', 'zmenki', 'izleti', 'projekti', 'vikendi', 'startaupi'];

  var T = {
    sl: {
      nav_activities: 'Aktivnosti', nav_archive: 'Arhiv', nav_about: 'O nas', menu: 'Meni',
      // cat = množina (navigacija, filtri); catOne = ednina (oznaka na kartici)
      cat: { pogovori: 'Pogovori', zmenki: 'Zmenki', izleti: 'Izleti',
             projekti: 'Projekti', vikendi: 'Vikendi', startaupi: 'Startupi' },
      catOne: { pogovori: 'Pogovor', zmenki: 'Zmenek', izleti: 'Izlet',
                projekti: 'Projekt', vikendi: 'Vikend', startaupi: 'Startup' },
      back: { pogovori: 'Nazaj na pogovore', zmenki: 'Nazaj na zmenke', izleti: 'Nazaj na izlete',
              projekti: 'Nazaj na projekte', vikendi: 'Nazaj na vikende', startaupi: 'Nazaj na startupe' },
      travelogues: 'Potopisi', podcast: 'Podkast', faculty: 'UP FTŠ Turistica',
      footer_program: 'Program', footer_contact: 'Kontakt', footer_follow: 'Sledi nam',
      footer_archive: 'Arhiv dogodkov', footer_tagline: 'Pilotni R&amp;R program 2018–2023',
      organizers: 'Organizatorji dogodka', authors: 'Besedilo pripravil-a',
      gallery: 'Galerija slik', close: 'Zapri', prev: 'Prejšnja', next: 'Naslednja',
      no_results: 'Ni zadetkov. Poskusi z drugim iskalnim nizom.',
      load_error: 'Podatkov ni bilo mogoče naložiti.',
      not_found_title: 'Aktivnosti ni bilo mogoče najti',
      not_found_body: 'Povezava je morda zastarela. Vse aktivnosti najdeš v arhivu.',
      back_archive: 'Nazaj na arhiv',
      count: function (n) {
        var r100 = n % 100;
        if (r100 === 1) return n + ' aktivnost';
        if (r100 === 2) return n + ' aktivnosti';
        if (r100 === 3 || r100 === 4) return n + ' aktivnosti';
        return n + ' aktivnosti';
      },
      other_lang: 'ENG', other_lang_full: 'English'
    },
    en: {
      // Oznake povzete po obstoječi angleški različici (engstoudioturistica.softr.app).
      nav_activities: 'Activities', nav_archive: 'Archive', nav_about: 'About us', menu: 'Menu',
      cat: { pogovori: 'Talks', zmenki: 'Dates', izleti: 'Trips',
             projekti: 'Projects', vikendi: 'Weekends', startaupi: 'Startups' },
      catOne: { pogovori: 'Talk', zmenki: 'Date', izleti: 'Trip',
                projekti: 'Project', vikendi: 'Weekend', startaupi: 'Startup' },
      back: { pogovori: 'Back to talks', zmenki: 'Back to dates', izleti: 'Back to trips',
              projekti: 'Back to projects', vikendi: 'Back to weekends', startaupi: 'Back to startups' },
      travelogues: 'Journal', podcast: 'Podcast', faculty: 'UP FTŠ Turistica',
      footer_program: 'Programme', footer_contact: 'Contact', footer_follow: 'Follow us',
      footer_archive: 'Activity archive', footer_tagline: 'Pilot R&amp;D programme 2018–2023',
      organizers: 'Organised by', authors: 'Text by',
      gallery: 'Image gallery', close: 'Close', prev: 'Previous', next: 'Next',
      no_results: 'No matches. Try a different search term.',
      load_error: 'Could not load the data.',
      not_found_title: 'Activity not found',
      not_found_body: 'The link may be outdated. You can find every activity in the archive.',
      back_archive: 'Back to the archive',
      count: function (n) { return n + (n === 1 ? ' activity' : ' activities'); },
      other_lang: 'SLO', other_lang_full: 'Slovensko'
    }
  }[LANG];

  var EXTERNAL = {
    travelogues: 'https://mirror.xyz/0x15f338B9D1f64a34cBbCB4c22969fF9131546De1',
    podcast:     'https://anchor.fm/stoudio-turistica',
    faculty:     'https://www.turistica.si/',
    facebook:    'https://www.facebook.com/stoudioturistica',
    instagram:   'https://www.instagram.com/stoudioturistica/',
    linkedin:    'https://www.linkedin.com/company/stoudio-turistica/'
  };

  var MONTHS = {
    sl: ['januar', 'februar', 'marec', 'april', 'maj', 'junij',
         'julij', 'avgust', 'september', 'oktober', 'november', 'december'],
    en: ['January', 'February', 'March', 'April', 'May', 'June',
         'July', 'August', 'September', 'October', 'November', 'December']
  };

  // --- pomožne funkcije / helpers -------------------------------------------
  function el(sel, root) { return (root || document).querySelector(sel); }
  function els(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  /** Pot do korena strani — podstrani v /en/ dobijo '../'. */
  var BASE = (function () {
    var s = document.currentScript;
    if (!s) return '';
    return s.getAttribute('src').replace(/assets\/js\/site\.js.*$/, '');
  })();

  /** Vir (slika, JSON, CSS) — vedno relativno na koren strani. */
  function asset(path) { return BASE + path; }

  /** Stran v trenutnem jeziku. */
  function page(key) {
    var p = PAGES[key];
    if (!p) return BASE;
    return BASE + (LANG === 'en' ? 'en/' : '') + p[LANG];
  }

  /** Ista stran v drugem jeziku. */
  function pageOtherLang(key) {
    var other = LANG === 'en' ? 'sl' : 'en';
    var p = PAGES[key] || PAGES.home;
    return BASE + (other === 'en' ? 'en/' : '') + p[other];
  }

  function formatDate(iso) {
    if (!iso) return '';
    var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso);
    if (!m) return iso;
    var d = parseInt(m[3], 10), mon = MONTHS[LANG][parseInt(m[2], 10) - 1];
    return LANG === 'en' ? (d + ' ' + mon + ' ' + m[1]) : (d + '. ' + mon + ' ' + m[1]);
  }

  function formatRange(start, finish) {
    if (!start) return '';
    if (!finish || finish === start) return formatDate(start);
    var a = /^(\d{4})-(\d{2})-(\d{2})/.exec(start);
    var b = /^(\d{4})-(\d{2})-(\d{2})/.exec(finish);
    if (a && b && a[1] === b[1] && a[2] === b[2]) {
      var d1 = parseInt(a[3], 10);
      return LANG === 'en' ? (d1 + '–' + formatDate(finish)) : (d1 + '.–' + formatDate(finish));
    }
    return formatDate(start) + ' – ' + formatDate(finish);
  }

  function year(iso) {
    var m = /^(\d{4})/.exec(iso || '');
    return m ? m[1] : '';
  }

  /** Prosti URL-ji v besedilu → klikabilne povezave (po escapanju). */
  function linkify(text) {
    return esc(text).replace(/(https?:\/\/[^\s<)]+)/g, function (u) {
      var trail = '';
      while (/[.,;:!?)]$/.test(u)) { trail = u.slice(-1) + trail; u = u.slice(0, -1); }
      return '<a href="' + u + '" target="_blank" rel="noopener noreferrer">' + u + '</a>' + trail;
    });
  }

  function normalize(s) {
    return String(s || '').toLowerCase()
      .replace(/[čć]/g, 'c').replace(/š/g, 's').replace(/ž/g, 'z').replace(/đ/g, 'd');
  }

  /** Povzetek v ustreznem jeziku, s padcem nazaj na drugega, če manjka. */
  function lead(a) { return (LANG === 'en' ? (a.leadEn || a.lead) : (a.lead || a.leadEn)) || ''; }
  /** Ednina — oznaka posamezne aktivnosti ("Zmenek", ne "Zmenki"). */
  function catLabel(a) {
    return T.catOne[a.category] || (LANG === 'en' ? a.catLabelEn : a.catLabel);
  }

  function activityHref(a) { return page('aktivnost') + '?id=' + encodeURIComponent(a.id); }

  // --- glava / header -------------------------------------------------------
  function renderHeader() {
    var host = el('#site-header');
    if (!host) return;
    var current = document.body.getAttribute('data-page') || '';

    var subItems = CATEGORY_ORDER.map(function (key) {
      return '<li><a href="' + page(key) + '"' +
             (current === key ? ' aria-current="page"' : '') + '>' + T.cat[key] + '</a></li>';
    }).join('');

    host.className = 'site-header';
    host.innerHTML =
      '<div class="wrap site-header__inner">' +
        '<a class="brand" href="' + page('home') + '">' +
          '<img src="' + asset('assets/brand/logo.png') + '" alt="UP FTŠ sTOUdio Turistica" width="1673" height="404">' +
        '</a>' +
        '<button class="nav-toggle" type="button" aria-expanded="false" aria-controls="primary-nav">' +
          '<span></span><span class="visually-hidden">' + T.menu + '</span>' +
        '</button>' +
        '<nav class="nav" id="primary-nav" aria-label="' + T.nav_activities + '"><ul>' +
          '<li class="has-sub" data-open="false">' +
            '<button type="button" aria-expanded="false">' + T.nav_activities + '</button>' +
            '<ul class="sub">' + subItems +
              '<li><a href="' + EXTERNAL.travelogues + '" target="_blank" rel="noopener">' + T.travelogues + '</a></li>' +
              '<li><a href="' + EXTERNAL.podcast + '" target="_blank" rel="noopener">' + T.podcast + '</a></li>' +
            '</ul>' +
          '</li>' +
          '<li><a href="' + page('arhiv') + '"' + (current === 'arhiv' ? ' aria-current="page"' : '') + '>' + T.nav_archive + '</a></li>' +
          '<li><a href="' + page('o-nas') + '"' + (current === 'o-nas' ? ' aria-current="page"' : '') + '>' + T.nav_about + '</a></li>' +
          '<li class="nav-lang"><a href="' + pageOtherLang(current) + '" hreflang="' + (LANG === 'en' ? 'sl' : 'en') +
            '" title="' + T.other_lang_full + '">' + T.other_lang + '</a></li>' +
        '</ul></nav>' +
      '</div>';

    var toggle = el('.nav-toggle', host);
    toggle.addEventListener('click', function () {
      var open = host.getAttribute('data-nav-open') === 'true';
      host.setAttribute('data-nav-open', String(!open));
      toggle.setAttribute('aria-expanded', String(!open));
    });

    els('.has-sub', host).forEach(function (li) {
      var btn = el('button', li);
      btn.addEventListener('click', function (e) {
        e.stopPropagation();
        var open = li.getAttribute('data-open') === 'true';
        li.setAttribute('data-open', String(!open));
        btn.setAttribute('aria-expanded', String(!open));
      });
    });

    document.addEventListener('click', function (e) {
      els('.has-sub', host).forEach(function (li) {
        if (!li.contains(e.target)) {
          li.setAttribute('data-open', 'false');
          el('button', li).setAttribute('aria-expanded', 'false');
        }
      });
    });

    document.addEventListener('keydown', function (e) {
      if (e.key !== 'Escape') return;
      els('.has-sub', host).forEach(function (li) { li.setAttribute('data-open', 'false'); });
      host.setAttribute('data-nav-open', 'false');
    });
  }

  // --- noga / footer --------------------------------------------------------
  function renderFooter() {
    var host = el('#site-footer');
    if (!host) return;

    var cats = CATEGORY_ORDER.map(function (key) {
      return '<li><a href="' + page(key) + '">' + T.cat[key] + '</a></li>';
    }).join('');

    host.className = 'site-footer';
    host.innerHTML =
      '<div class="wrap">' +
        '<div class="footer-grid">' +
          '<div>' +
            '<h3>' + T.nav_activities + '</h3><ul>' + cats +
              '<li><a href="' + EXTERNAL.travelogues + '" target="_blank" rel="noopener">' + T.travelogues + '</a></li>' +
              '<li><a href="' + EXTERNAL.podcast + '" target="_blank" rel="noopener">' + T.podcast + '</a></li>' +
            '</ul>' +
          '</div>' +
          '<div>' +
            '<h3>' + T.footer_program + '</h3><ul>' +
              '<li><a href="' + page('o-nas') + '">' + T.nav_about + '</a></li>' +
              '<li><a href="' + page('arhiv') + '">' + T.footer_archive + '</a></li>' +
              '<li><a href="' + EXTERNAL.faculty + '" target="_blank" rel="noopener">' + T.faculty + '</a></li>' +
              '<li><a href="' + pageOtherLang(document.body.getAttribute('data-page') || 'home') +
                '" hreflang="' + (LANG === 'en' ? 'sl' : 'en') + '">' + T.other_lang_full + '</a></li>' +
            '</ul>' +
          '</div>' +
          '<div>' +
            '<h3>' + T.footer_contact + '</h3><ul>' +
              '<li>Obala 11a, 6320 Portorož</li>' +
              '<li><a href="mailto:stoudio.turistica@fts.upr.si">stoudio.turistica@fts.upr.si</a></li>' +
            '</ul>' +
          '</div>' +
          '<div>' +
            '<h3>' + T.footer_follow + '</h3><ul>' +
              '<li><a href="' + EXTERNAL.facebook + '" target="_blank" rel="noopener">Facebook</a></li>' +
              '<li><a href="' + EXTERNAL.instagram + '" target="_blank" rel="noopener">Instagram</a></li>' +
              '<li><a href="' + EXTERNAL.linkedin + '" target="_blank" rel="noopener">LinkedIn</a></li>' +
            '</ul>' +
          '</div>' +
        '</div>' +
        '<div class="footer-bottom">' +
          '<span>© UP FTŠ sTOUdio Turistica</span>' +
          '<span>' + T.footer_tagline + '</span>' +
        '</div>' +
      '</div>';
  }

  // --- podatki / data -------------------------------------------------------
  // Seznami berejo lahki indeks (brez dolgih besedil), podrobnosti polni JSON.
  var cache = {};
  function load(file) {
    if (!cache[file]) {
      cache[file] = fetch(asset('data/' + file)).then(function (r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.json();
      });
    }
    return cache[file];
  }
  function loadIndex() { return load('activities-index.json'); }
  function loadFull()  { return load('activities.json'); }

  function failure(host, e) {
    host.className = '';
    host.innerHTML = '<p class="empty">' + T.load_error + ' (' + esc(e.message) + ')</p>';
  }

  // --- kartice / cards ------------------------------------------------------
  function cardHtml(a) {
    var cover = a.cover || (a.images || []).filter(function (i) { return i.kind !== 'video'; })[0];
    var media = cover
      ? '<div class="card__media"><img src="' + asset(cover.thumb || cover.src) + '" alt="" loading="lazy" ' +
        'decoding="async" width="' + (cover.w || 800) + '" height="' + (cover.h || 600) + '"></div>'
      : '';
    var people = (a.organizers || []).slice(0, 3).join(', ');
    return '<article class="card">' + media +
      '<div class="card__body">' +
        '<span class="tag">' + esc(catLabel(a)) + '</span>' +
        '<h3 class="card__title"><a href="' + activityHref(a) + '">' + esc(a.title) + '</a></h3>' +
        '<p class="card__lead">' + esc(lead(a)) + '</p>' +
        '<div class="card__meta">' +
          '<span>' + esc(formatRange(a.start, a.finish)) + '</span>' +
          (people ? '<span>' + esc(people) + '</span>' : '') +
        '</div>' +
      '</div>' +
    '</article>';
  }

  function renderCards(host, list) {
    if (!list.length) {
      host.className = '';
      host.innerHTML = '<p class="empty">' + T.no_results + '</p>';
      return;
    }
    host.className = 'grid';
    host.innerHTML = list.map(cardHtml).join('');
  }

  function byDateDesc(x, y) { return (y.start || '').localeCompare(x.start || ''); }

  // --- seznam kategorije / category list ------------------------------------
  function initCategoryPage() {
    var host = el('#activity-list');
    if (!host) return;
    var cat = document.body.getAttribute('data-category');

    loadIndex().then(function (all) {
      var list = (cat ? all.filter(function (a) { return a.category === cat; }) : all).sort(byDateDesc);
      renderCards(host, list);
      var count = el('#activity-count');
      if (count) count.textContent = T.count(list.length);
    }).catch(function (e) { failure(host, e); });
  }

  // --- arhiv z iskanjem in filtri / archive ---------------------------------
  function initArchivePage() {
    var host = el('#archive-list');
    if (!host) return;

    var search = el('#archive-search');
    var chipHost = el('#archive-chips');
    var countHost = el('#archive-count');
    var activeCat = 'all';
    var all = [];

    if (chipHost) {
      chipHost.innerHTML =
        '<button class="chip" type="button" data-cat="all" aria-pressed="true">' +
          (LANG === 'en' ? 'All' : 'Vse') + '</button>' +
        CATEGORY_ORDER.map(function (key) {
          return '<button class="chip" type="button" data-cat="' + key + '" aria-pressed="false">' +
                 T.cat[key] + '</button>';
        }).join('');

      chipHost.addEventListener('click', function (e) {
        var btn = e.target.closest('.chip');
        if (!btn) return;
        activeCat = btn.getAttribute('data-cat');
        els('.chip', chipHost).forEach(function (b) { b.setAttribute('aria-pressed', String(b === btn)); });
        apply();
      });
    }

    if (search) search.addEventListener('input', debounce(apply, 140));

    function apply() {
      var q = normalize(search ? search.value.trim() : '');
      var list = all.filter(function (a) {
        if (activeCat !== 'all' && a.category !== activeCat) return false;
        if (!q) return true;
        // a.body je na voljo samo tu — arhiv nalaga polni JSON prav zaradi iskanja.
        var hay = a._hay || (a._hay = normalize([a.title, a.lead, a.leadEn, a.body,
                             catLabel(a), T.cat[a.category], year(a.start),
                             (a.organizers || []).join(' ')].join(' ')));
        return q.split(/\s+/).every(function (w) { return hay.indexOf(w) !== -1; });
      });
      renderCards(host, list);
      if (countHost) countHost.textContent = T.count(list.length);
    }

    // Arhiv je edina stran, ki išče po celotnem besedilu, zato bere polni JSON;
    // ostale strani se zadovoljijo z manjšim indeksom.
    loadFull().then(function (data) {
      all = data.slice().sort(byDateDesc);
      apply();
    }).catch(function (e) { failure(host, e); });
  }

  function debounce(fn, ms) {
    var t;
    return function () { clearTimeout(t); t = setTimeout(fn, ms); };
  }

  // --- domača stran / home --------------------------------------------------
  function initFeatured() {
    var host = el('#featured');
    if (!host) return;
    var ids = (host.getAttribute('data-ids') || '').split(',').map(function (s) { return s.trim(); });

    loadIndex().then(function (all) {
      var byId = {};
      all.forEach(function (a) { byId[a.id] = a; });
      var list = ids.map(function (id) { return byId[id]; }).filter(Boolean);
      if (!list.length) list = all.slice(0, 3);
      host.className = 'featured';
      host.innerHTML = list.map(cardHtml).join('');
    }).catch(function () { host.innerHTML = ''; });
  }

  function initLatest() {
    var host = el('#latest');
    if (!host) return;
    loadIndex().then(function (all) {
      renderCards(host, all.slice().sort(byDateDesc).slice(0, 6));
    }).catch(function () { host.innerHTML = ''; });
  }

  // --- podrobnosti / detail -------------------------------------------------
  function initDetailPage() {
    var host = el('#activity-detail');
    if (!host) return;

    var params = new URLSearchParams(location.search);
    var id = params.get('id') || params.get('recordId');
    var slug = params.get('slug');

    loadFull().then(function (all) {
      var a = null;
      if (id) a = all.filter(function (x) { return x.id === id; })[0];
      if (!a && slug) a = all.filter(function (x) { return x.slug === slug; })[0];

      if (!a) {
        document.title = T.not_found_title + ' — sTOUdio Turistica';
        host.innerHTML =
          '<div class="wrap narrow">' +
            '<div><a class="backlink" href="' + page('arhiv') + '">' + T.back_archive + '</a></div>' +
            '<h1>' + T.not_found_title + '</h1>' +
            '<p class="lede">' + T.not_found_body + '</p>' +
          '</div>';
        return;
      }

      document.title = a.title + ' — sTOUdio Turistica';
      var desc = el('meta[name="description"]');
      if (desc) desc.setAttribute('content', lead(a));

      var media = a.images || [];
      var pics  = media.filter(function (i) { return i.kind !== 'video'; });
      var clips = media.filter(function (i) { return i.kind === 'video'; });
      var hero  = pics[0];
      var rest  = pics.slice(1);

      host.innerHTML =
        '<div class="wrap narrow">' +
          '<div><a class="backlink" href="' + page(a.category) + '">' +
            esc(T.back[a.category] || T.back_archive) + '</a></div>' +
          '<div><span class="tag tag--solid">' + esc(catLabel(a)) + '</span></div>' +
          '<h1>' + esc(a.title) + '</h1>' +
          '<p class="lede">' + esc(lead(a)) + '</p>' +
          '<div class="article__meta">' +
            '<span>' + esc(formatRange(a.start, a.finish)) + '</span>' +
            '<span>' + esc(a.type) + '</span>' +
          '</div>' +
        '</div>' +
        (hero ? '<div class="wrap narrow"><div class="article__hero">' +
          '<img src="' + asset(hero.src) + '" alt="' + esc(a.title) + '" fetchpriority="high" ' +
          'decoding="async" width="' + (hero.w || 1200) + '" height="' + (hero.h || 800) + '">' +
        '</div></div>' : '') +
        '<div class="wrap narrow">' +
          '<div class="article__body">' + paragraphs(a.body) + '</div>' +
          (rest.length ? '<div class="gallery" id="gallery">' + rest.map(function (im, i) {
            return '<button type="button" data-index="' + (i + 1) + '">' +
              '<img src="' + asset(im.thumb || im.src) + '" alt="" loading="lazy" decoding="async">' +
            '</button>';
          }).join('') + '</div>' : '') +
          clips.map(function (v) {
            return '<video class="article__video" controls preload="none" playsinline ' +
                   'src="' + asset(v.src) + '"></video>';
          }).join('') +
          peopleHtml(a) +
        '</div>';

      if (pics.length > 1) initLightbox(pics);
    }).catch(function (e) {
      host.innerHTML = '<div class="wrap narrow"><p class="empty">' + T.load_error +
                       ' (' + esc(e.message) + ')</p></div>';
    });
  }

  function paragraphs(body) {
    if (!body) return '';
    return String(body).split(/\n{2,}/).map(function (chunk) {
      return '<p>' + linkify(chunk.trim()) + '</p>';
    }).join('');
  }

  function peopleHtml(a) {
    var blocks = '';
    if (a.organizers && a.organizers.length) {
      blocks += '<div><h3>' + T.organizers + '</h3><ul>' +
        a.organizers.map(function (n) { return '<li>' + esc(n) + '</li>'; }).join('') + '</ul></div>';
    }
    if (a.authors && a.authors.length) {
      blocks += '<div><h3>' + T.authors + '</h3><ul>' +
        a.authors.map(function (n) { return '<li>' + esc(n) + '</li>'; }).join('') + '</ul></div>';
    }
    return blocks ? '<div class="people">' + blocks + '</div>' : '';
  }

  // --- lightbox --------------------------------------------------------------
  function initLightbox(images) {
    var gallery = el('#gallery');
    if (!gallery) return;

    var box = document.createElement('div');
    box.className = 'lightbox';
    box.setAttribute('role', 'dialog');
    box.setAttribute('aria-modal', 'true');
    box.setAttribute('aria-label', T.gallery);
    box.innerHTML =
      '<button class="lightbox__close" type="button" aria-label="' + T.close + '">&times;</button>' +
      '<button class="lightbox__nav lightbox__nav--prev" type="button" aria-label="' + T.prev + '">&#8249;</button>' +
      '<img alt="">' +
      '<button class="lightbox__nav lightbox__nav--next" type="button" aria-label="' + T.next + '">&#8250;</button>' +
      '<span class="lightbox__count"></span>';
    document.body.appendChild(box);

    var img = el('img', box);
    var counter = el('.lightbox__count', box);
    var index = 0;
    var lastFocus = null;

    function show(i) {
      index = (i + images.length) % images.length;
      img.src = asset(images[index].src);
      counter.textContent = (index + 1) + ' / ' + images.length;
    }

    function open(i) {
      lastFocus = document.activeElement;
      show(i);
      box.classList.add('is-open');
      document.body.style.overflow = 'hidden';
      el('.lightbox__close', box).focus();
    }

    function close() {
      box.classList.remove('is-open');
      document.body.style.overflow = '';
      if (lastFocus) lastFocus.focus();
    }

    gallery.addEventListener('click', function (e) {
      var btn = e.target.closest('button[data-index]');
      if (btn) open(parseInt(btn.getAttribute('data-index'), 10));
    });

    el('.lightbox__close', box).addEventListener('click', close);
    el('.lightbox__nav--prev', box).addEventListener('click', function () { show(index - 1); });
    el('.lightbox__nav--next', box).addEventListener('click', function () { show(index + 1); });
    box.addEventListener('click', function (e) { if (e.target === box) close(); });

    document.addEventListener('keydown', function (e) {
      if (!box.classList.contains('is-open')) return;
      if (e.key === 'Escape') close();
      if (e.key === 'ArrowLeft') show(index - 1);
      if (e.key === 'ArrowRight') show(index + 1);
    });
  }

  // --- zagon / boot ---------------------------------------------------------
  function boot() {
    renderHeader();
    renderFooter();
    initFeatured();
    initLatest();
    initCategoryPage();
    initArchivePage();
    initDetailPage();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
