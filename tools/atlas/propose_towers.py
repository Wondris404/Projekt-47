"""Review-only high-rise proposals. Does not change the shipped Atlas assets."""
import hashlib
import json
from pathlib import Path
from generate_levels import Model, shade, CREAM, DARK, GOLD, GLASS

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/atlas-towers-proposal'


def tower(m,x,y,z,w,d,floors,wall,glass,balconies=False):
    # Separate floor geometry preserves the continuous facade window bands.
    for floor in range(floors):
        zz=z+floor*.72
        m.box(x,y,zz,w,d,.72,wall,label='floor')
        fy=y+d/2+.02;fx=x+w/2+.02
        m.face([(x-w/2+.16,fy,zz+.18),(x+w/2-.16,fy,zz+.18),(x+w/2-.16,fy,zz+.57),(x-w/2+.16,fy,zz+.57)],shade(glass,1))
        m.face([(fx,y-d/2+.16,zz+.18),(fx,y+d/2-.16,zz+.18),(fx,y+d/2-.16,zz+.57),(fx,y-d/2+.16,zz+.57)],shade(glass,.7))
        if balconies:
            m.box(x,fy+.14,zz+.04,w+.2,.45,.12,CREAM,label='balcony slab')
    return z+floors*.72


def proposal(kind,level):
    m=Model();n=level-1
    if kind=='bank':
        m.box(0,0,0,4.5+n*.4,3.3,1.2,'#a5a399',CREAM,'stone podium')
        for x in [-1.5,-.5,.5,1.5]:
            m.box(x,1.8,0,.28,.4,1.45,CREAM,label='entrance column')
        m.box(0,1.8,1.45,4.1,.75,.28,CREAM,GOLD,'portico')
        top=tower(m,-.3,-.25,1.2,2.7,2.5,7+n*3,'#c6bfa4','#466d80')
        # Art-deco setbacks and a golden pyramidal crown, not a giant coin.
        m.box(-.3,-.25,top,2.3,2.1,.45,CREAM,GOLD,'setback crown')
        m.box(-.3,-.25,top+.45,1.7,1.5,.5,CREAM,GOLD,'upper crown')
        m.cylinder(-.3,-.25,top+.95,.8,.85,GOLD,0,'pyramidal spire')
        if n>=1:tower(m,1.8,-.5,1.2,1.4,2,4,'#b8b5a4','#466d80')
        if n>=2:tower(m,-1.4,1,1.2,1.5,1.2,3,'#b8b5a4','#466d80')
    elif kind=='casino':
        m.box(0,0,0,5.6+n*.3,3.3,1.3,'#413f50','#bc9753','casino podium')
        m.box(0,1.8,.7,4.4,.8,.25,GOLD,label='illuminated entrance canopy')
        heights=[]
        for x,floors in [(-1.2,7+n*2),(1.2,5+n*2)]:
            top=tower(m,x,-.4,1.3,1.8,2.2,floors,'#63596b','#d9b87c')
            heights.append(top)
            m.box(x,-.4,top,2,2.4,.25,GOLD,label='gold roof rim')
            m.box(x,-.4,top+.25,1.3,1.6,.5,'#7a466d',GOLD,'stepped crown')
            # Magenta corner light strips make the casino distinct at map scale.
            m.box(x+.82,.74,1.3,.16,.12,top-1.3,'#d77ba2',label='neon corner')
        # A geometric diamond marquee; no real brand logo.
        y=1.85;z=1.9
        m.face([(-.7,y,z),(0,y,z+1),(.7,y,z),(0,y,z-.65)],shade(GOLD,1.1),.1)
        if n>=1:m.box(0,-.4,heights[1]-1.1,1.1,1.8,.7,'#76687b',GOLD,'skybridge')
        if n>=2:tower(m,0,1,1.3,2.1,1.1,4,'#63596b','#d9b87c')
    elif kind=='hotel':
        m.box(0,0,0,4.8+n*.4,3.5,1.1,'#d4c5ab','#8bada8','hotel podium')
        top=tower(m,-.4,-.3,1.1,2.8,2.6,8+n*2,'#d8cdb6','#5f9caa',True)
        m.box(-.4,-.3,top,3.1,2.9,.22,CREAM,label='roof terrace')
        m.box(-.4,-.3,top+.22,1.9,1.6,.10,'#61c0cc',label='rooftop pool')
        m.sign(-.4,1.12,top-.15,'H',DARK,1.8,1.5)
        m.box(0,2,.7,3.3,1,.2,CREAM,label='porte cochere')
        for x in [-1.4,1.4]:m.box(x,2,0,.18,.18,.7,CREAM)
        if n>=1:tower(m,1.7,-.4,1.1,1.3,2.1,4,'#d8cdb6','#5f9caa',True)
        if n>=2:tower(m,-1.8,.8,1.1,1.2,1.5,6,'#d8cdb6','#5f9caa',True)
    else:raise ValueError(kind)
    return m


def main():
    (OUT/'sprites').mkdir(parents=True,exist_ok=True)
    families={k:[proposal(k,l) for l in (1,2,3)] for k in ('bank','casino','hotel')}
    # One common camera for all nine drafts: height and growth remain comparable.
    raw=[((x-y)*5.3,(x+y)*2.65-z*5.3) for f in families.values() for m in f for x,y,z in m.points]
    left,right=min(p[0] for p in raw),max(p[0] for p in raw)
    top,bottom=min(p[1] for p in raw),max(p[1] for p in raw)
    scale=min(58/(right-left),60/(bottom-top))
    projection=(scale,32-(left+right)*scale/2,62-bottom*scale)
    records=[]
    for kind,family in families.items():
        for level,m in enumerate(family,1):
            m.projection=projection
            im=m.render();name=f'{kind}_{level}.png';im.save(OUT/'sprites'/name)
            lo=[min(p[i] for p in m.points) for i in range(3)]
            hi=[max(p[i] for p in m.points) for i in range(3)]
            records.append(dict(id=kind,level=level,path='sprites/'+name,bounds=[lo,hi],parts=m.parts,sha256=hashlib.sha256(im.tobytes()).hexdigest()))
    (OUT/'manifest.json').write_text(json.dumps(dict(status='proposal only; not used by game',origin='Original procedural artwork for Projekt-47',license='LicenseRef-Projekt47-Original',projection=projection,models=records),ensure_ascii=False,indent=2)+'\n')
    assert len({r['sha256'] for r in records})==9
    print('Prepared nine distinct high-rise proposals; production assets unchanged')


if __name__=='__main__':main()
