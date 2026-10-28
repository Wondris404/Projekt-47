"""Create faithful before/after contact sheets from captured PNGs (Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
r=ROOT/'audit/screenshots/atlas-update';out=r/'pairs';out.mkdir(exist_ok=True)
for p in sorted(r.glob('*_before.png')):
    q=p.with_name(p.name.replace('_before','_after'))
    if not q.exists():continue
    a=Image.open(p).convert('RGB');b=Image.open(q).convert('RGB')
    im=Image.new('RGB',(a.width+b.width,max(a.height,b.height)+30),'#18212a')
    im.paste(a,(0,30));im.paste(b,(a.width,30));d=ImageDraw.Draw(im)
    d.text((12,8),'PRED',fill='white');d.text((a.width+12,8),'PO',fill='white')
    im.save(out/p.name.replace('_before','_pair'))
print('Pairs:',len(list(out.glob('*.png'))))
