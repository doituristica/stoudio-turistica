# Predajno pismo za univerzitetno IT službo

Kratek tehnični opis strani in kaj je treba narediti. Vsebino spodnjega osnutka
lahko prilepiš v e-pošto.

---

## Osnutek e-pošte

> **Zadeva:** Prenos strani sTOUdio Turistica na univerzitetni strežnik
>
> Pozdravljeni,
>
> stran **stoudio.turistica.si** trenutno teče na zunanji platformi Softr, ki jo
> ukinjamo. Pripravili smo nadomestno, popolnoma statično različico z enako vsebino
> in prosim za pomoč pri prenosu na naš strežnik.
>
> **Živ predogled:** `<sem prilepi povezavo do GitHub Pages>`
>
> **Kaj stran potrebuje:** nič posebnega. Gre za statične datoteke — HTML, CSS,
> JavaScript in slike. **Brez PHP, brez podatkovne baze, brez Node.js**, brez
> kakršnihkoli procesov v ozadju. Zadošča navaden spletni prostor.
>
> **Kaj je treba narediti:**
>
> 1. Vsebino mape `site/` prekopirati v koren spletnega prostora za to domeno.
>    (Pozor: vsebino mape, ne mape same — `index.html` mora biti v korenu.)
> 2. Poskrbeti, da se prenesejo tudi datoteke, ki se začnejo s piko — `.htaccess`
>    in `.nojekyll`. FTP odjemalci jih pogosto skrijejo.
> 3. Domeno `stoudio.turistica.si` preusmeriti s Softra na ta strežnik.
> 4. Urediti HTTPS certifikat za domeno.
>
> **Prosim, da Softra ne ugašamo, dokler nova stran ne deluje na domeni** — sicer
> bo stran vmes nedosegljiva.
>
> Podrobnosti so spodaj. Za vprašanja sem na voljo.
>
> Lep pozdrav,
> Jaka Godejša

---

## Tehnične podrobnosti

### Obseg

| | |
|---|---|
| Velikost | ~32 MB |
| Število datotek | ~350 |
| Največja datoteka | 12,4 MB (MP4 video v enem zapisu) |
| Tehnologija | statični HTML, CSS, JavaScript |
| Odvisnosti | **nobene** — brez PHP, baze, Node.js, zunanjih CDN-jev |

Stran ne kliče nobene zunanje storitve. Pisave, slike in podatki so lokalni,
zato deluje tudi na omrežju brez dostopa do interneta.

### Struktura

```
site/                     ← vsebina te mape gre v koren spletnega prostora
  index.html              domača stran (slovensko)
  en/index.html           angleška različica
  aktivnost.html          podrobnosti aktivnosti
  data/*.json             vsebina 44 aktivnosti
  assets/                 slike, pisave, CSS, JavaScript
  .htaccess               konfiguracija za Apache (glej spodaj)
  404.html   robots.txt   sitemap.xml
```

### Zahteve strežnika

- Kateri koli spletni strežnik, ki streže statične datoteke (Apache, nginx, IIS).
- Priporočeno: Apache z omogočenimi moduli `mod_rewrite`, `mod_expires`,
  `mod_deflate` in `mod_headers`. Priložena datoteka `.htaccess` jih uporabi za
  lepše naslove, predpomnjenje in stiskanje.
- **Če ti moduli niso na voljo, stran vseeno deluje** — le naslovi bodo vsebovali
  končnico `.html` in nalaganje bo nekoliko počasnejše. `.htaccess` v tem primeru
  brez škode ignorirajte.
- Strežnik mora streči `.json` in `.woff2` z ustreznim MIME tipom. `.htaccess`
  to nastavi sam, sicer je treba dodati:
  `application/json .json` in `font/woff2 .woff2`.

### Če je strežnik nginx

`.htaccess` na nginxu ne deluje. Enakovredna konfiguracija:

```nginx
server {
    root /pot/do/site;
    index index.html;

    # URL-ji brez končnice
    location / {
        try_files $uri $uri.html $uri/ =404;
    }

    error_page 404 /404.html;

    # predpomnjenje
    location ~* \.(jpg|jpeg|png|svg|webp|mp4|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    location ~* \.(css|js)$ { expires 7d; }
    location ~* \.json$     { expires 1h; }

    gzip on;
    gzip_types text/css application/javascript application/json image/svg+xml;
}
```

### Ohranitev obstoječih povezav

Softr je posamezne aktivnosti objavljal na naslovih oblike
`stoudio.turistica.si/aktivnosti?recordId=recXXXX`. Ti naslovi so razposlani po
družbenih omrežjih in indeksirani v iskalnikih.

Nova stran jih lovi na dva načina — datoteka `aktivnosti.html` preusmeri sama,
`.htaccess` pa naredi isto s pravilom `301`. Ni potrebno nič dodatnega, samo
prepričajte se, da je datoteka `aktivnosti.html` prenesena.

### Posodabljanje vsebine

Stran je arhiv zaključenega programa (2018–2023), zato posodobitev praktično ne bo.
Če pride do popravka, se spremeni datoteka `site/data/activities.json` in prenese
na strežnik — nič drugega.

### Kontakt za vsebino

Jaka Godejša — `<sem vpiši svoj službeni e-naslov>`

> Namenoma brez e-naslova: repozitorij je javen in naslovi v njem se hitro znajdejo
> na spam seznamih. Vpiši ga šele v e-pošto tehnikom, ne v to datoteko.
