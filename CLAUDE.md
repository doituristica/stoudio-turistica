# CLAUDE.md

Navodila za delo v tem repozitoriju.

## Kaj je to

Statična dvojezična arhivska stran **UP FTŠ sTOUdio Turistica** (pilotni R&R program
2018–2023). Nadomešča prejšnjo postavitev na Softru z Airtable bazo, ki se ukinja.

Vsebina je **zamrznjena**: 44 aktivnosti, 151 fotografij, 1 video. Program je zaključen,
zato nove vsebine praktično ne bo — to je arhiv, ne živa stran.

- Živo: <https://doituristica.github.io/stoudio-turistica/>
- Repozitorij: `doituristica/stoudio-turistica` (organizacija, ne osebni račun)
- Cilj: `stoudio.turistica.si`, ko bo spremenjen DNS zapis

## Temeljna omejitev

**Na tem računalniku ni Node.js in ni Pythona.** Vse orodje je Windows PowerShell 5.1.
Ne predlagaj `npm`, `npx`, `pip` ali karkoli, kar ju potrebuje — tudi ne za enkratno
opravilo. Če rabiš obdelavo, jo napiši v PowerShellu.

Objavljena stran nima build koraka: `site/` je končni izdelek, ki ga strežnik postreže
kot je.

## Struktura

```
site/                      ← objavi se samo to
  *.html                   slovenske strani
  en/*.html                angleške
  data/activities.json           polni podatki (bereta arhiv in stran s podrobnostmi)
  data/activities-index.json     lahki indeks brez besedil (berejo seznami)
  assets/{img,brand,fonts,css,js}
  .htaccess  _headers  404.html  robots.txt  sitemap.xml  .nojekyll
tools/                     PowerShell gradnja
backup/img-orig/           originalne slike — se NE objavijo
data/raw_arhiv.json        surov odgovor Airtabla, brez e-naslovov
data/raw_arhiv.private.json  polna kopija, .gitignore
```

## Ukazi

```powershell
.\tools\build.ps1                  # pregradi vse (~5 s)
.\tools\build.ps1 -Refresh         # najprej znova pobere iz Airtabla + nove slike
.\tools\build.ps1 -BaseUrl https://stoudio.turistica.si   # domena v sitemap.xml
powershell -ExecutionPolicy Bypass -File tools\serve.ps1  # predogled na :8080
```

`build.ps1` požene po vrsti: `build-data` → `optimize-images` → `fetch-fonts` → `build-sitemap`.
Vrstni red ni poljuben: `optimize-images` popravi `activities.json` in ustvari indeks,
`fetch-fonts` pa bere končne strani, da izračuna nabor znakov.

Vse skripte so idempotentne. Po spremembi vsebine vedno poženi `build.ps1` pred commitom.

## Pasti, ki so nas že ujele

**PowerShell 5.1 bere `.ps1` brez BOM kot ANSI.** Skripte v `tools/` morajo ostati
**čisti ASCII** — šumnik v komentarju ali nizu razbije parser. Posebne znake piši kot
kodne točke: `[char]0x2013`.

**Airtable povezave do slik potečejo v ~enem dnevu.** `-Refresh` mora zato takoj
prenesti tudi slike. Star `raw_arhiv.json` sam po sebi ne omogoča več pridobivanja slik.

**Ena priloga je MP4, ki se pretvarja, da je `.jpg`.** Vrsto določa MIME tip, ne končnica
imena. Polje `kind` v JSON-u je `image` ali `video`; videi se ne stiskajo in se izrišejo
kot predvajalnik.

**`optimize-images` pretvori `.png` v `.jpg`.** Zato `build-data` in `optimize-images`
iščeta obstoječe datoteke po *korenu imena*, ne po polnem imenu — sicer bi ob vsakem
zagonu znova prenašala oziroma znova stiskala iste slike.

**Ne domnevaj, da se vrstni red v DOM-u ujema med seznami.** Logotipi podpornikov so bili
napačno povezani, ker sem predpostavil, da vrstni red povezav ustreza vrstnemu redu slik.
Kadar prenašaš karkoli z originala, preberi **pare** neposredno iz DOM-a in preveri.

**Osebni podatki.** `raw_arhiv.json` je iz Airtabla prišel s 40 e-naslovi študentov in
mentorjev. `build-data -Refresh` jih zdaj samodejno odstrani. Pred vsakim pushom preveri,
da v objavljenih datotekah ni zasebnih naslovov — službeni `@fts.upr.si` so v redu.

## Konvencije

- **Vse v slovenščini**: komentarji, dokumentacija, commit sporočila, odgovori uporabniku.
  Izjema so ASCII-only skripte v `tools/`, kjer so komentarji v angleščini brez šumnikov.
- Commit sporočila brez šumnikov (PowerShell here-string jih pokvari).
- HTML strani so tanke lupine; glavo, nogo in sezname izriše `site/assets/js/site.js`.
- Nova stran potrebuje vnos v `PAGES` v `site.js` (sicer preklopnik jezika pade na domačo)
  in v `$pairs` v `tools/build-sitemap.ps1`.
- Jezik določa `<html lang>`. Ključ `data-page` je **enak v obeh jezikih**, razlikujejo se
  samo imena datotek.

## Preverjanje pred commitom

1. `.\tools\build.ps1`
2. predogled na `localhost:8080`, preveri obe jezikovni različici
3. preveri notranje povezave — ob zadnji napaki jih je bilo 210 in ena je bila izmišljena
4. `git push` sproži GitHub Actions, ki objavi `site/` na Pages v ~20 s

Zaslonske slike v brskalniškem podoknu pogosto potečejo; preverjanje prek
`javascript_tool` (DOM, računani slogi, `performance`) je zanesljivejše.

## Zmogljivost — ne pokvari

Domača stran: 7 zahtevkov, ~435 KB. Doseženo z:
slike stisnjene 34,7 → 19,5 MB, ločene sličice `-t.jpg` za kartice, pisava kot podnabor
dejansko rabljenih znakov (199 → 29 KB, brez Google Fonts), deljen JSON, `preload` za
pisavo in hero sliko.

Če dodaš vsebino z novimi znaki, **poženi `fetch-fonts.ps1`**, sicer bo manjkajoč znak
padel na sistemsko pisavo.
