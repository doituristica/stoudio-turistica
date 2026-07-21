# sTOUdio Turistica — statična spletna stran

Poustvarjena različica [stoudio.turistica.si](https://stoudio.turistica.si/) kot **popolnoma statična
dvojezična stran** brez Softra, brez Airtable naročnine in brez strežniške logike. Vse podatke in
slike ima lokalno, zato jo lahko gostiš zastonj (GitHub Pages, Netlify, Cloudflare Pages, ali kar
spletni prostor Turistice).

## Kaj je notri

```
site/                        ← to je vse, kar se objavi (32 MB)
  index.html                 domača stran (SL)
  pogovori · zmenki · izleti · projekti · vikendi · startaupi .html
  arhiv.html                 vseh 44 aktivnosti + iskanje po celotnem besedilu
  aktivnost.html             podrobnosti ene aktivnosti (?id=recXXXX)
  aktivnosti.html            preusmeritev za stare Softr povezave (?recordId=…)
  o-nas.html   404.html
  en/                        angleška različica (ista logika, iste slike)
    index · talks · dates · trips · projects · weekends · startups
    archive · about · activity .html
  data/activities.json       polni podatki (44 zapisov) — bere jih arhiv in podrobnosti
  data/activities-index.json lahki indeks brez dolgih besedil — berejo ga seznami
  assets/img/recXXXX/…       151 slik + 151 sličic (-t.jpg) + 1 video
  assets/brand/…             logotip, hero slike, logotipi podpornikov
  assets/fonts/…             Noto Sans, podnabor 29 KB
  assets/css/style.css       oblikovanje
  assets/css/fonts.css       @font-face (generirano)
  assets/js/site.js          navigacija, seznami, iskanje, galerija, jeziki
  _headers                   cache pravila za Netlify / Cloudflare Pages
  robots.txt   sitemap.xml   .nojekyll

tools/                       gradnja (Windows PowerShell, brez Node in Pythona)
backup/img-orig/             originalne slike iz Airtabla — se NE objavijo
data/raw_arhiv.json          surov odgovor Airtable (varnostna kopija)
```

Ni build koraka za objavo, ni odvisnosti, ni `node_modules`. Datoteke iz `site/` so končni izdelek.

## Lokalni predogled

```powershell
powershell -ExecutionPolicy Bypass -File tools\serve.ps1
```

Odpri <http://localhost:8080>. Strežnik podpira tudi URL-je brez končnice
(`/zmenki` → `zmenki.html`), tako kot Netlify in Cloudflare Pages.

> Odpiranje `site\index.html` neposredno z dvoklikom **ne deluje** — brskalnik zaradi
> varnostnih pravil (CORS) ne sme prebrati `activities.json` s `file://`. Potrebuješ strežnik.

## Objava

| Gostovanje | Kako | Opomba |
|---|---|---|
| **Cloudflare Pages** | povleci mapo `site/` v dashboard | priporočeno; URL-ji brez končnice in `_headers` delujejo sami |
| **Netlify** | povleci mapo `site/` na netlify.com/drop | isto |
| **GitHub Pages** | commitaj `site/` in ga nastavi kot izvor | URL-ji **potrebujejo** `.html`; `_headers` se ignorira |
| **Obstoječi strežnik Turistice** | prekopiraj vsebino `site/` v koren | najbolj smiselno, če ohraniš domeno |

Pred objavo poženi sitemap s pravo domeno in popravi vrstico `Sitemap:` v `site/robots.txt`,
če se domena razlikuje:

```powershell
.\tools\build.ps1 -BaseUrl https://stoudio.turistica.si
```

### Ohranitev starih povezav

Softr je posamezne aktivnosti objavljal na naslovih oblike
`stoudio.turistica.si/aktivnosti?recordId=recXXXX`. Ta stran ima isto aktivnost na
`aktivnost.html?id=recXXXX`.

Stari naslovi so razposlani po svetu — v objavah na družbenih omrežjih, v mailih, v
Googlovem indeksu — in tam ostanejo tudi po ugasnitvi Softra. Datoteka `aktivnosti.html`
je zato zgolj preusmeritev: prebere `recordId` in pošlje obiskovalca na pravo stran.
Ničesar ne kliče in ne potrebuje interneta.

Smiselna je **samo, če obdržiš domeno `stoudio.turistica.si`**. Ob selitvi na novo domeno
stari linki umrejo ne glede na vse in datoteko lahko izbrišeš.

## Gradnja in osvežitev podatkov

```powershell
.\tools\build.ps1              # pregradi vse iz shranjenih podatkov (~2 s)
.\tools\build.ps1 -Refresh     # najprej znova pobere zapise IZ AIRTABLA in nove slike
```

`build.ps1` po vrsti požene:

| Skripta | Kaj naredi |
|---|---|
| `build-data.ps1` | Airtable → `activities.json`, prenese manjkajoče slike |
| `optimize-images.ps1` | stisne slike, naredi sličice, dopolni JSON, zgradi indeks |
| `fetch-fonts.ps1` | pobere Noto Sans, podnabor na dejansko rabljene znake, uskladi `preload` |
| `build-sitemap.ps1` | `sitemap.xml` za oba jezika s `hreflang` |

Vse skripte so idempotentne — ponovni zagon ne prenese in ne prekodira ničesar po nepotrebnem.

> **Pomembno:** Airtable vrača podpisane povezave do slik, ki potečejo v približno enem dnevu.
> Zato `-Refresh` vedno takoj prenese tudi slike — surov `raw_arhiv.json` sam po sebi
> po dnevu ni več uporaben za pridobivanje slik.

### Ko bosta Softr in Airtable ugasnjena

**Objavljena stran tega ne opazi.** V `site/` ni nobene povezave na Softr ali Airtable —
vseh 44 aktivnosti, 151 slik in en video so lokalne datoteke.

Preneha delovati samo stikalo `-Refresh`, ki gre po sveže podatke skozi Softrov endpoint.
To ni težava: program je zaključen (2018–2023), podatki so zamrznjeni, varnostni kopiji
pa sta `data/raw_arhiv.json` (surov odgovor Airtabla) in `backup/img-orig/` (originalne slike).

Po ugasnitvi torej:

- uporabljaj `.\tools\build.ps1` **brez** `-Refresh` — dela izključno z lokalnimi datotekami;
- vsebino urejaj neposredno v `site/data/activities.json`;
- če bi kdaj vseeno rabil ponoven uvoz iz še živega Airtabla, v `tools/build-data.ps1`
  zamenjaj vir z uradnim API-jem (`https://api.airtable.com/v0/{baseId}/{tableId}` z osebnim
  dostopnim žetonom) — preostanek verige ostane enak.

## Hitrost

Domača stran ob prvem obisku: **7 zahtevkov, ~435 KB** (nestisnjeno; gostitelj z gzipom pošlje manj).
Kar je bilo narejeno:

- **Slike stisnjene: 34,7 MB → 19,5 MB (−44 %)**, vsaka največ 1400 px pri kakovosti 80.
  Originali ostanejo v `backup/img-orig/`, tako da je ponovna optimizacija vedno brez izgub.
- **Ločene sličice** (`-t.jpg`, 640 px) za kartice in galerijo — seznam s 44 karticami
  naloži ~40 KB na sličico namesto polne slike.
- **Pisava 199 KB → 29 KB.** Noto Sans se prenese samo v podnaboru znakov, ki jih stran
  dejansko uporablja (`fetch-fonts.ps1` jih prebere iz strani in JSON-a).
- **Brez Google Fonts.** Pisava je gostovana lokalno: dva manj TLS rokovanja pred izrisom
  besedila in nič IP naslovov obiskovalcev proti Googlu (GDPR).
- **`preload`** za pisavo in hero sliko, `loading="lazy"` + `decoding="async"` za vse ostalo,
  `width`/`height` na vsaki sliki, da se postavitev ne premika med nalaganjem.
- **Deljeni JSON:** seznami berejo 55 KB indeks, polnih 148 KB naloži samo arhiv
  (ki edini išče po celotnem besedilu) in stran s podrobnostmi.
- **`_headers`** nastavi enoletni cache za slike in pisave.

Edina velika datoteka je **12,4 MB video** pri zapisu *First NFT Dinner in Slovenia*.
Ostane nedotaknjen (za prekodiranje bi bil potreben ffmpeg) in se naloži šele ob kliku
na predvajanje (`preload="none"`).

## Dvojezičnost

Obe različici tečeta na isti kodi in istih podatkih. Jezik določa `<html lang>`;
`site.js` po tem izbere besedila vmesnika, obliko datumov (`24. junij 2023` / `24 June 2023`)
in povzetke (`lead` / `leadEn`).

| SL | EN |
|---|---|
| `/zmenki.html` | `/en/dates.html` |
| `/pogovori.html` | `/en/talks.html` |
| `/izleti.html` | `/en/trips.html` |
| `/projekti.html` | `/en/projects.html` |
| `/vikendi.html` | `/en/weekends.html` |
| `/startaupi.html` | `/en/startups.html` |
| `/arhiv.html` | `/en/archive.html` |
| `/o-nas.html` | `/en/about.html` |
| `/aktivnost.html` | `/en/activity.html` |

Angleška besedila so povzeta po obstoječi angleški različici
(`engstoudioturistica.softr.app`), ne strojno prevedena. Strani so povezane s
`hreflang` in preklopnikom SLO/ENG v navigaciji, ki vodi na isto stran v drugem jeziku.

**Ena omejitev:** v Airtablu je dolgo besedilo (`Description`) shranjeno samo v angleščini —
slovenski je le povzetek. Zato je na slovenski strani s podrobnostmi naslov in povzetek v
slovenščini, celotno besedilo pa v angleščini. Tako je bilo tudi na originalni strani.
Če želiš slovenska besedila, jih je treba dopisati v Airtable kot novo polje.

## Struktura podatkov

```json
{
  "id": "recZWNLbVVlYc06NC",
  "slug": "living-learning-lab",
  "title": "Living Learning Lab",
  "type": "sTOUdio WEEKEND",
  "category": "vikendi",
  "catLabel": "Vikend",
  "catLabelEn": "Weekend",
  "start": "2023-06-24",
  "finish": "2023-06-29",
  "lead": "…slovenski povzetek…",
  "leadEn": "…angleški povzetek…",
  "body": "…celotno besedilo…",
  "organizers": ["Tadej Rogelja", "…"],
  "authors": [],
  "images": [
    { "src": "assets/img/recZWNLbVVlYc06NC/01.jpg",
      "thumb": "assets/img/recZWNLbVVlYc06NC/01-t.jpg",
      "kind": "image", "w": 767, "h": 512 }
  ]
}
```

`kind` je `image` ali `video` — v Airtablu je namreč ena priloga MP4, ki se je pretvarjala,
da je `.jpg`. Videi se ne stiskajo in se na strani izrišejo kot predvajalnik.

Kategorije: `pogovori` (TALK), `zmenki` (DATE), `izleti` (TRIP),
`projekti` (PROJECT), `vikendi` (WEEKEND), `startaupi` (STARTUP).

## Kaj ni prekopirano

- **Potopisi / Journal** (mirror.xyz) in **Podkast** (anchor.fm) — zunanji storitvi, povezavi ostajata.
