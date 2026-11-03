# Kontrola modelu lode

Pracovný zoznam pre človeka, ktorý skladá trup. Nie je to správa z merania. Číslo, ktoré si neodčítal zo súboru po poslednom behu, do popisu PR nepatrí.

Os, materiály a veľkosti sú v `tools/ships/blender/README.md`. Tu je poradie práce a to, čoho sa diff nesmie dotknúť.

## Znova vyrobiť to, čo generátor už vie

Z koreňa repozitára, nie z iného priečinka:

```text
python3 tools/ships/build_ships.py
python3 tools/ships/render_preview.py
```

Prvý príkaz zapíše hrdinov `assets/models/ships/{cargo,bulk,merchant,submarine}.glb` a LOD do `assets/models/ships/lod/<meno>_lod1.glb` a `_lod2.glb`. Do `data/ships.json` nezapisuje.

Druhý prepíše len `docs/ships/after/<meno>_hero.png` a `<meno>_profile.png`. Priečinok `docs/ships/before/` ním nehýb.

Sieť z Blenderu tento generátor nečíta. Keď je hotový hero GLB mimo generátora, LOD vedľa neho (nie do `lod/`):

```text
bash tools/ships/make_lods.sh cesta/k/lodi.glb
```

Skript volá gltfpack a nič iné. Presné flagy:

```text
gltfpack -i cesta/k/lodi.glb -o cesta/k/lodi_lod1.glb -si 0.18 -sp
gltfpack -i cesta/k/lodi.glb -o cesta/k/lodi_lod2.glb -si 0.025 -sp
```

`-si` je pomer voči vstupu (gltfpack 1.3). `-sp` je permissive režim cez šev atribútu. Bez neho `-si 0.18` a `-si 0.04` na `cargo.glb` (25 930 tris) skončili na 7 489 a 7 440, teda LOD2 nevznikol. S `-sp` ten istý beh dal 4 770 a 1 474. `submarine.glb` má 16 776 tris, tie isté príkazy dali 3 102 a 566, mimo pásma, lebo vstup je pod 20 tisíc. Výsledok sa neráta, kým trojuholníky nespočítaš na tom GLB, ktorý si práve vyrobil. Vstupný súbor skript nemení. Predvolená kvantizácia gltfpacku (`KHR_mesh_quantization`) vo výstupe je; `-noq` sa nepridáva. Neprepína sa ani `-c`, `-sa`, `-kn`. Meno uzla `ship` gltfpack pri tomto príkaze zahodí.

Kontrola, ktorá súbor nemení (report ide na stdout, kópia je v dočasnom priečinku):

```text
bash tools/ships/validate_glb.sh cesta/k/lodi.glb cesta/k/lodi_lod1.glb cesta/k/lodi_lod2.glb
```

Hľadá `gltf_validator` alebo `gltf-validator`. Keď binár nie je, skončí **kódom 2** a vypíše, že validácia nebežala. Kód 2 nie je pass. Na tomto stroji binár je `/opt/gltf-validator/gltf_validator` (symlink `/usr/local/bin/gltf_validator`, vydanie 2.0.0-dev.3.10). `gltfpack` je `/usr/bin/gltfpack` 1.3 a `gltf-transform` je `/usr/bin/gltf-transform` 4.5.1, oba z `npm install -g @gltf-transform/cli gltfpack`. Záložná cesta, keby globálny npm zlyhal, je `/opt/gltf-tools/node_modules/.bin/` — tam teraz nič nie je, lebo globálna inštalácia prešla. Blender, ak treba otvoriť `.blend`, je `/opt/blender/blender` (4.2.9 LTS). Žiadny z týchto nástrojov nie je v gite.

Unit testy CI týmto skriptom nespúšťaj a nepridávaj workflow, ktorý by červenú unit úlohu vedel zmeniť. Tieto príkazy sú lokálne.

## Rozpočet trojuholníkov

| Úroveň | Trojuholníky | Súbor |
| --- | --- | --- |
| LOD0 | 20 000–40 000 | hero GLB ≤ 4 MB |
| LOD1 | 4 000–6 000 | ≤ 1 MB |
| LOD2 | 800–1 500 | ≤ 1 MB |

LOD2 má zostať čitateľná silueta tej istej triedy, nie hrudka.

## Materiály

Najviac päť materiálov na loď. Kontajnery rôznych farieb sedia na **jednom atlase** a jednom materiáli. Materiál `c_red`, `c_blue` a ďalšie osobitne sú starý postup generátora v `tools/ships/meshlib.py`. Nový model ho neopakuje. Päť materiálov sa počíta v hotovom GLB, nie v počte vrstiev v Blendri, ak sa pri exporte zlúčia.

## Snímky pred a po

Pred výmenou tvaru odlož, čo hráč vidí teraz:

- `docs/ships/before/` — starý stav (kocky aj to, čo už v priečinku je). Nemazať a neprepisovať novým renderom.
- `docs/ships/after/<trieda>_hero.png` — LOD0, trištvrte.
- `docs/ships/after/<trieda>_profile.png` — ten istý mesh zboku.

Keď meníš generátor, `render_preview.py` prepíše len `after/`. Do popisu daj obe cesty. Prázdny `after/` alebo obrázok z inej lode sa nepočíta. Snímku z Blenderu bez uloženého GLB, ktorý si práve exportoval, tiež nie.

## Na čo diff nesmie siahnuť

- `SAVE_VERSION` a migrácia save v `scripts/autoload/GameState.gd`.
- Golden testy a ich očakávané výstupy. Nový beh sa nesmie stať novou referenciou len preto, že starý test padol.
- `tests/catalog_field_lock.txt`.
- Bunker: `assets/models/bunker/` a pravidlá bunkra.
- Štatistiky lodí. Rýchlosť, kapacita, cena, náklad a názvy v `data/ships.json` ostávajú. Generátor ciest modelov neprepisuje.

Ak úloha potrebuje zmenu niektorého z týchto bodov, zastav a neschovávaj ju do commitu s meshom.

## Zakázané zdroje

Žiadne meshe z generátora obrázkov ani z modelu, ktorý „vymodeluje loď“. Žiadny Sketchfab, Free3D ani iná stiahnutá sieť. Kenney trupy, ktoré už v hre sú (carrier, tanker, fregata a ďalšie), sa týmto zoznamom neprepisujú.

## Pred odovzdaním

- [ ] V GLB je Y hore, príď na −Z, kýl na Y = 0, dĺžka pozdĺž Z asi 3,4, šírka pozdĺž X.
- [ ] LOD0, LOD1 a LOD2 sú v pásmach vyššie a súbory držia 4 MB / 1 MB.
- [ ] V GLB je najviac päť materiálov a farby kontajnerov sú jeden atlas.
- [ ] `validate_glb.sh` dobehol na hrdinovi aj na oboch LOD. Kód 2 (chýba validátor) nie je zaškrtnuté.
- [ ] `make_lods.sh` alebo generátor zapísal oba LOD a vstupný hero súbor ostal rovnaký.
- [ ] `docs/ships/before/` a `docs/ships/after/` ukazujú tú istú triedu pred a po.
- [ ] `git diff` nemá `SAVE_VERSION`, golden, `tests/catalog_field_lock.txt`, bunker ani štatistiky lodí.
- [ ] V commite nie je workflow, ktorý farbí unit CI.
