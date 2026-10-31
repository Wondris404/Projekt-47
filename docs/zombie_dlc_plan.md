# Halloween DLC – ako je hra zložená (Z0)

Hra ide po dňoch: `GameState.simulate_day` spustí trh, firmy a geopolitiku, `_finish_day` posunie dátum. Keď je DLC vypnuté, `ZombieSystem.daily` sa vráti hneď a nič z toho nemení.

Save je v3. Nové polia `game_settings` (zombie_mode, zombie_start_money) a slovník `zombie` sú voliteľné. Starý save ich nemá, po načítaní je mód vypnutý.

Noviny na main sú `GameState.news` / `post_news` a krátky zoznam v záložke štátu. Samostatný panel Noviny z fázy B v main ešte nie je, preto DLC píše do `post_news` a pri zapnutom móde otvorí vlastné okno správ.

Mapa kreslí štáty (Atlas aj Pixelová). Mestá sú v `cities.json` (Kraków je v PL). Tie mestá sú regióny nákazy. Doprava: `Transport` (železnica a potrubie, ktoré hráč postaví) a statické prístavy v `Society`. `atlas_traffic.gd` kreslí vlaky; lietadlá DLC idú tadiaľ istým spôsobom, lebo lode z fázy C v main nie sú.

Budovy sú v `recipes.json` (bez nových id, offshore ostáva finančná firma). Firmy a AI bežia v `IndustrySystem` a `RivalSystem`. PMC a vládne zmluvy sú v `Society`, kúpa štátu v `Empire`. Vlastné zbrojovky a flotila lodí v main nie sú, DLC má preto vlastné helikoptéry, stíhačky a stavby safe zóny. Modely v `assets/models/` sú zástupné (Quaternius sa nestiahol).
