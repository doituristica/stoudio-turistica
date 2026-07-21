# Prošnja za spremembo DNS zapisa

Stran sTOUdio Turistica je pripravljena in že teče. Za prehod s Softra je potrebna
**ena sprememba v DNS-u** — vsebine ni treba prenašati na noben strežnik.

- **Živ predogled:** https://g0dex.github.io/stoudio-turistica/
- **Izvorna koda:** https://github.com/g0dex/stoudio-turistica

---

## Osnutek e-pošte

> **Zadeva:** Sprememba DNS zapisa za stoudio.turistica.si
>
> Pozdravljeni,
>
> stran **stoudio.turistica.si** trenutno teče na zunanji platformi Softr, ki jo
> ukinjamo. Pripravili smo nadomestno statično različico z enako vsebino, ki je že
> objavljena in deluje:
>
> **https://g0dex.github.io/stoudio-turistica/**
>
> Gostuje na GitHub Pages, kar za nas pomeni brez stroškov in brez vzdrževanja
> strežnika. Prosim za **eno spremembo v DNS coni `turistica.si`**:
>
> ```
> briši:   stoudio   A       35.158.87.123
> dodaj:   stoudio   CNAME   g0dex.github.io.
> ```
>
> Če vaš sistem za to ime ne dovoli zapisa CNAME, delujejo tudi štirje A zapisi:
>
> ```
> stoudio   A   185.199.108.153
> stoudio   A   185.199.109.153
> stoudio   A   185.199.110.153
> stoudio   A   185.199.111.153
> ```
>
> **HTTPS ni treba urejati.** GitHub po spremembi sam pridobi in obnavlja
> certifikat Let's Encrypt. Preveril sem, da v coni ni zapisov CAA, ki bi to
> blokirali.
>
> **Prosim, da mi javite, ko bo zapis spremenjen** — takoj zatem moram v GitHubu
> potrditi domeno, sicer stran na njej ne bo delovala. Softr bomo ugasnili šele
> potem, ko bo nova stran na domeni preverjeno delovala, da vmes ni izpada.
>
> Hvala in lep pozdrav,
> Jaka Godejša
> `<sem vpiši svoj službeni e-naslov>`

> Namenoma brez e-naslova v tej datoteki: repozitorij je javen in naslovi v njem
> se hitro znajdejo na spam seznamih. Vpiši ga šele v e-pošto.

---

## Vrstni red — pomembno

1. **IT spremeni DNS zapis.** Razširjanje traja od nekaj minut do nekaj ur.
2. **Šele nato** se v GitHubu nastavi domena po meri (`Settings → Pages → Custom domain`,
   ali z ukazom spodaj). Prej tega ne delaj — GitHub bi začel predogledno povezavo
   preusmerjati na domeno, ki še ne dela, in ostal bi brez delujočega predogleda.
3. GitHub izda certifikat (nekaj minut do 24 ur), nato se vklopi **Enforce HTTPS**.
4. **Softr se ugasne zadnji**, ko nova stran na domeni preverjeno dela.

Ukaz za drugi korak (ko DNS že kaže na GitHub):

```powershell
gh api -X PUT repos/g0dex/stoudio-turistica/pages -f cname=stoudio.turistica.si
```

Nato preveri stanje certifikata:

```powershell
gh api repos/g0dex/stoudio-turistica/pages
```

---

## Zakaj DNS namesto prenosa na strežnik

| | GitHub Pages | Univerzitetni strežnik |
|---|---|---|
| Delo za IT | ena vrstica v DNS-u | prenos datotek, Apache, certifikat |
| Strošek | 0 | 0 (že plačan) |
| Vzdrževanje | nič | posodobitve strežnika, obnova certifikata |
| HTTPS | samodejno | ročno |
| Hitrost | globalni CDN | en strežnik |
| Nadzor | GitHub | univerza |

Prenos na strežnik ostaja odprt kadarkoli — v repozitoriju sta že pripravljeni
datoteki `site/.htaccess` (Apache) in `site/_headers` (Netlify/Cloudflare), navodila
za nginx pa so v `README.md`. Preseliti pomeni prekopirati mapo `site/`; nič drugega
se ne spremeni.

---

## Kaj je treba urediti na naši strani

Repozitorij je zaenkrat na **osebnem računu** `g0dex`. Za arhiv fakultetnega programa
to ni dobro — če račun ugasne ali se lastnik odseli, fakulteta izgubi stran in nima
nobenega vzvoda.

Priporočen popravek (brezplačen, ~10 minut):

1. Na <https://github.com/account/organizations/new> ustvari brezplačno organizacijo,
   npr. `ftsturistica` ali `stoudio-turistica`.
2. Povabi vsaj še enega lastnika s fakultete (npr. Dejana Križaja kot idejnega vodjo).
3. Repozitorij prenesi v organizacijo:
   `Settings → General → Danger Zone → Transfer ownership`.
4. Po prenosu se spremeni tudi naslov predogleda in cilj CNAME zapisa —
   `g0dex.github.io` postane `<organizacija>.github.io`. **Zato to naredi pred
   prošnjo za DNS**, da tehnikom ni treba spreminjati dvakrat.

Po prenosu ostaneš vzdrževalec z vsemi pravicami, lastništvo pa je institucionalno.

---

## Tehnični opis strani

| | |
|---|---|
| Velikost | ~32 MB, ~350 datotek |
| Tehnologija | statični HTML, CSS, JavaScript |
| Odvisnosti | **nobene** — brez PHP, baze, Node.js, zunanjih CDN-jev |
| Vsebina | 44 aktivnosti (2018–2023), 151 fotografij, 1 video |
| Jezika | slovenščina in angleščina |

Stran ne kliče nobene zunanje storitve — pisave, slike in podatki so lokalni.

**Stare povezave ostanejo žive.** Softr je aktivnosti objavljal na naslovih
`stoudio.turistica.si/aktivnosti?recordId=recXXXX`; ti so razposlani po družbenih
omrežjih in indeksirani v iskalnikih. Nova stran jih samodejno preusmeri na pravo mesto.
