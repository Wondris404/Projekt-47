"""One grouped asset audit; runtime/save/upgrade checks live in atlas_levels.gd."""
import hashlib
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2]
directory = root/'assets/map_models/levels'
manifest = json.loads((directory/'manifest.json').read_text())
rows = manifest['models']
ids = {r['id'] for r in json.loads((root/'data/industries.json').read_text())} | {'bank','hq','port','highway'}
assert {(r['id'],r['level']) for r in rows} == {(i,l) for i in ids for l in (1,2,3)}
assert len(rows) == 195
for kind in ids:
    family = sorted([r for r in rows if r['id']==kind],key=lambda r:r['level'])
    assert family[0]['projection']==family[1]['projection']==family[2]['projection'],kind
    for a,b in zip(family,family[1:]):
        sa=[a['bounds'][1][i]-a['bounds'][0][i] for i in range(3)]
        sb=[b['bounds'][1][i]-b['bounds'][0][i] for i in range(3)]
        assert all(y>=x-1e-6 for x,y in zip(sa,sb)) and any(y>x+1e-6 for x,y in zip(sa,sb)),kind
        assert a['parts']!=b['parts'],kind
for size in (24,32,48,64):
    hashes={}
    for row in rows:
        im=Image.open(directory/row['file']).convert('RGBA')
        if size==64:
            assert im.size==(64,72)
            assert hashlib.sha256(im.tobytes()).hexdigest()==row['sha256']
            x,y,right,bottom=im.getbbox()
            assert x>0 and y>0 and right<64 and bottom<72,(row['file'],im.getbbox())
        im=im.resize((size,round(size*72/64)),Image.Resampling.NEAREST)
        digest=hashlib.sha256(im.tobytes()).hexdigest()
        assert digest not in hashes,(size,row['file'],hashes.get(digest))
        hashes[digest]=row['file']
print('P47_ASSET_AUDIT_OK 195 models; geometry growth; fixed family projection; no clipping; no duplicates at 24/32/48/64 px')
