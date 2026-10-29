"""Original, deterministic isometric pixel models for Atlas (no external meshes).

Geometry is authored in world units and projected at a fixed scale. Levels add
real floors, wings and machinery; no sprite is scaled to manufacture an upgrade.
Run: python tools/atlas/generate_levels.py (Pillow). Legacy/UI assets are untouched.
"""
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/map_models/levels"
CREAM, DARK, GLASS = "#d4d0b9", "#344956", "#81bac4"
RED, GOLD, GREEN = "#ae5041", "#e3b45b", "#518a68"


def shade(c, f):
    c = c.lstrip("#")
    return tuple(min(255, round(int(c[i:i+2], 16)*f)) for i in (0, 2, 4)) + (255,)


class Model:
    def __init__(self):
        self.faces = []
        self.points = []
        self.parts = []
        self.overlays = []
        self.projection = (1.0,32.0,54.0)

    def project(self,p):
        x, y, z = p
        scale,ox,oy=self.projection
        return (round(ox + (x-y)*5.3*scale), round(oy + ((x+y)*2.65-z*5.3)*scale))

    def face(self, ps, color, order=0):
        self.points.extend(ps)
        depth = sum(x+y+z*.55 for x, y, z in ps)/len(ps)
        self.faces.append((depth+order, ps, color))

    def box(self, x, y, z, w, d, h, c=CREAM, roof=None, label="block"):
        a,b = x-w/2,x+w/2
        e,f = y-d/2,y+d/2
        self.parts.append(dict(kind=label, center=[x,y,z], size=[w,d,h]))
        self.face([(a,f,z),(b,f,z),(b,f,z+h),(a,f,z+h)],shade(c,.78))
        self.face([(b,e,z),(b,f,z),(b,f,z+h),(b,e,z+h)],shade(c,.58))
        self.face([(a,e,z+h),(b,e,z+h),(b,f,z+h),(a,f,z+h)],shade(roof or c,1.05))

    def roof(self,x,y,z,w,d,c=RED):
        a,b=x-w/2,x+w/2; e,f=y-d/2,y+d/2
        self.face([(a,e,z),(b,e,z),(b,y,z+1),(a,y,z+1)],shade(c,1.1))
        self.face([(a,y,z+1),(b,y,z+1),(b,f,z),(a,f,z)],shade(c,.85))
        self.face([(b,e,z),(b,f,z),(b,y,z+1)],shade(c,.6))

    def cylinder(self,x,y,z,r,h,c=CREAM,top_r=None,label="tank"):
        top_r = r if top_r is None else top_r
        n=12
        low=[(x+r*math.cos(i*math.tau/n),y+r*math.sin(i*math.tau/n),z) for i in range(n)]
        high=[(x+top_r*math.cos(i*math.tau/n),y+top_r*math.sin(i*math.tau/n),z+h) for i in range(n)]
        self.parts.append(dict(kind=label,center=[x,y,z],size=[2*max(r,top_r),2*max(r,top_r),h]))
        for i in range(n):
            j=(i+1)%n
            self.face([low[i],low[j],high[j],high[i]],shade(c,.65+.25*math.cos(i*math.tau/n-1)))
        self.face(high,shade(c,1.1))

    def beam(self,a,b,r=.14,c=DARK):
        # Axis-aligned sections and diagonal truss beams, with a square cross section.
        dx,dy,dz=(b[i]-a[i] for i in range(3))
        length=math.sqrt(dx*dx+dy*dy+dz*dz)
        if length==0:return
        if abs(dz)>abs(dx)+abs(dy): u=(r,0,0);v=(0,r,0)
        else:u=(0,0,r);v=(-dy/length*r,dx/length*r,0)
        corners=lambda p:[tuple(p[i]+su*u[i]+sv*v[i] for i in range(3)) for su,sv in [(-1,-1),(1,-1),(1,1),(-1,1)]]
        aa,bb=corners(a),corners(b)
        for i in range(4):self.face([aa[i],aa[(i+1)%4],bb[(i+1)%4],bb[i]],shade(c,.75+i*.08))

    def windows(self,x,y,z,w,d,h):
        for floor in range(max(1,int(h/1.15))):
            zz=z+.65+floor*1.15
            if zz>z+h-.2:continue
            for j in range(max(1,int(w/.8))):
                xx=x-w/2+.45+j*.8
                self.face([(xx-.22,y+d/2+.02,zz),(xx+.22,y+d/2+.02,zz),(xx+.22,y+d/2+.02,zz+.45),(xx-.22,y+d/2+.02,zz+.45)],shade(GLASS,1))

    def hall(self,x,y,w=3,d=2.5,h=2,c=CREAM,roof=DARK,gable=False):
        self.box(x,y,0,w,d,h,c,roof,"building")
        if gable:self.roof(x,y,h,w+.2,d+.2,roof)
        self.windows(x,y,0,w,d,h)
        self.box(x+.4,y+d/2+.04,0,.7,.08,1.3,DARK,label="entrance")

    def sign(self,x,y,z,mark,c=GOLD,w=2.4,h=1.6):
        # High contrast sign on the camera-facing facade, custom geometric glyphs.
        self.box(x,y,z,w,.18,h,c,label="sign:"+mark)
        glyph_start=len(self.faces)
        facade_depth=max(f[0] for f in self.faces[-3:])+.02
        if mark=="PREDAJ":self.overlays.append(((x,y,z+h*.5),"PREDAJ"))
        xx=x-w/2+.2; yy=y+.11; zz=z+.2
        def line(a,b,color=CREAM,r=.10):self.beam((xx+a[0],yy,zz+a[1]),(xx+b[0],yy,zz+b[1]),r,color)
        if mark=="cross":
            line((w*.4,0),(w*.4,h-.4),RED,.16);line((.1,h*.35),(w-.5,h*.35),RED,.16)
        elif mark in ["code","chart","link","shield","umbrella","bread","car","chip"]:
            paths={"code":[[(.7,0),(.1,.6),(.7,1.1)],[(1.3,0),(1.9,.6),(1.3,1.1)]],
                   "chart":[[(0,.1),(.5,.6),(1,.3),(1.8,1.1)]],
                   "link":[[(0,.5),(.6,1),(1.2,.5),(.6,0),(0,.5)],[(.8,.5),(1.4,1),(2,.5),(1.4,0),(.8,.5)]],
                   "shield":[[(.2,1.1),(1.7,1.1),(1.5,.2),(.95,-.1),(.4,.2),(.2,1.1)]],
                   "umbrella":[[(.1,.5),(.35,1),(.95,1.25),(1.55,1),(1.8,.5),(.1,.5)],[(.95,.65),(.95,-.1),(.65,-.2)]],
                   "bread":[[(.1,.2),(.1,.7),(.6,1),(1.6,1),(1.9,.7),(1.9,.2),(.1,.2)]],
                   "car":[[(0,.1),(0,.5),(.4,.6),(.65,1),(1.4,1),(1.7,.5),(2,.5),(2,.1),(0,.1)]],
                   "chip":[[(.3,.1),(1.5,.1),(1.5,1),(.3,1),(.3,.1)]]}
            for path in paths[mark]:
                for a,b in zip(path,path[1:]):line(a,b)
        elif mark=="coin":
            self.cylinder(x,y+.25,z+.15,.65,1.15,GOLD,label="coin emblem")
        elif mark=="H":
            line((.3,0),(.3,1.1));line((1.4,0),(1.4,1.1));line((.3,.55),(1.4,.55))
        else:
            # Banner lettering drawn as deliberately chunky letter stems.
            for i in range(4):line((i*.45,.15),(i*.45,.95),CREAM,.09)
        # These are facade emblems, not structural beams behind the sign. Keep
        # their lower strokes in front of the panel as well as their upper ones.
        for i in range(glyph_start,len(self.faces)):
            depth,points,color=self.faces[i]
            self.faces[i]=(max(depth,facade_depth)+(i-glyph_start)*.00001,points,color)

    def stack(self,x,y,z=0,h=4,c=RED):
        self.cylinder(x,y,z,.3,h,c,label="chimney")
        self.cylinder(x,y,z+h-.5,.33,.35,CREAM)

    def hvac(self,x,y,z):
        self.box(x,y,z,1,1,.65,"#9caeb1",label="roof cooling")
        self.cylinder(x,y,z+.65,.3,.08,DARK)

    def truss(self,x,y,h=5,c=GOLD):
        for dx in [-.6,.6]:
            for dy in [-.5,.5]:self.beam((x+dx,y+dy,0),(x+dx*.4,y+dy*.4,h),.13,c)
        for z in range(1,int(h)):
            self.beam((x-.6,y+.5,z),(x+.6,y+.5,z+.7),.09,c)
            self.beam((x-.6,y+.5,z),(x+.6,y+.5,z),.09,c)

    def crane(self,x,y,h=5):
        self.truss(x,y,h)
        self.beam((x-2,y,h),(x+2,y,h),.16,GOLD)
        self.beam((x-1.7,y,h),(x-1.7,y,h-2),.07,DARK)

    def vehicle(self,x,y,c=CREAM,truck=False):
        self.box(x,y,.3,1 if not truck else 2.3,.8,.65,c,label="truck" if truck else "van")
        self.box(x+.45,y,.3,.5,.8,.65,GLASS)
        for xx in [x-.35,x+.35]:self.box(xx,y+.43,.1,.3,.1,.35,DARK)

    def plane(self,x,y,z=0,tail_only=False):
        if not tail_only:
            self.box(x,y,z+.3,3,.5,.45,CREAM,label="aircraft fuselage")
            self.face([(x+.3,y-1.8,z+.45),(x+.6,y,z+.45),(x+.3,y+1.8,z+.45),(x-.5,y,z+.45)],shade(CREAM,1))
        top=3.8 if tail_only else 2.6
        self.face([(x-1.2,y,z+.5),(x-1.2,y,z+top),(x-.6,y,z+top),(x+.3,y,z+.5)],shade("#328bb1",1),.2)
        self.beam((x-1.1,y+.03,z+top-.9),(x-.4,y+.03,z+top-1.5),.14,CREAM)

    def cooling(self,x,y):
        self.cylinder(x,y,0,.95,2.7,CREAM,.55,"cooling tower base")
        self.cylinder(x,y,2.7,.55,2.4,CREAM,.7,"cooling tower neck")
        self.cylinder(x,y,5.1,.7,.1,DARK)

    def render(self):
        im=Image.new("RGBA",(64,72));d=ImageDraw.Draw(im)
        for _,ps,c in sorted(self.faces,key=lambda f:f[0]):d.polygon([self.project(p) for p in ps],fill=c)
        glyphs={"P":["110","101","110","100","100"],"R":["110","101","110","101","101"],"E":["111","100","110","100","111"],"D":["110","101","101","101","110"],"A":["010","101","111","101","101"],"J":["111","001","001","101","010"]}
        for pos,text in self.overlays:
            x,y=self.project(pos);x-=len(text)*2;y-=3
            d.rectangle((x-1,y-1,x+len(text)*4,y+5),fill=CREAM)
            for i,ch in enumerate(text):
                for yy,row in enumerate(glyphs[ch]):
                    for xx,on in enumerate(row):
                        if on=='1':d.point((x+i*4+xx,y+yy),fill=RED)
        return im


OFFICES={"ad_agency":3,"ai_firm":3.5,"finance_office":2.5,"insurance":2.8,
         "invest_fund":4.5,"software":3.3,"social_network":2,"trade_desk":2.7,
         "stock_broker":3.1,"hotel":4.2,"hq":6.5}
HALLS={"eshop","logistics_hub","warehouse","data_center","auto_plant","chip_fab",
       "electronics_plant","arms_plant","textile_mill","steel_mill","pharma_lab",
       "chem_plant","oil_refinery","gas_works","power_coal","gas_plant",
       "aircraft_plant","newspaper","tv_station","telecom","construction_co"}
SHOPS={"cafe","restaurant","bakery","supermarket","gym","auto_service","real_estate",
       "offshore","clinic","hospital","school_primary","school_high","university",
       "corp_academy","casino","pmc_unit","bank"}


def building(kind,level):
    m=Model();n=level-1
    # Fixed camera/ground anchor for every type and every level. No auto-fit.
    # New wings extend sideways; additional floors alter the top silhouette.
    if kind in OFFICES:
        h=OFFICES[kind]+n*.85
        w=2.6 if kind not in ["hq","invest_fund"] else 2
        m.hall(-.4,-.4,w,2.1,h,"#a2bdc1",GLASS)
        if n>=1:m.hall(1.55,-.5,1.3,2,2.3,CREAM,DARK)
        if n>=2:m.hall(-.3,1.5,2.8,1.1,1.6,CREAM,DARK)
        if kind=="ad_agency":
            m.box(-.4,-.4,h,.15,.15,.8,DARK);m.sign(-.4,-.4,h+.5,"banner",RED,3,1.7)
        elif kind=="ai_firm":
            for x in [-.9,.1]:m.box(x,-.3,h,.65,.8,1.1,DARK,label="external server enclosure")
            m.beam((-.4,-.4,h+1),(-.4,-.4,h+2.2),.12,CREAM)
            m.beam((-1,-.4,h+1.8),(.2,-.4,h+1.8),.1,GOLD)
        elif kind=="finance_office":m.sign(-.4,.75,h-.4,"coin",DARK)
        elif kind=="insurance":m.sign(-.4,.75,h-.3,"umbrella","#326b9a")
        elif kind=="invest_fund":
            m.box(-.4,-.4,h,1.7,1.8,.7,GLASS,label="glass crown")
            m.beam((-.4,-.4,h+.7),(-.4,-.4,h+1.5),.1,CREAM)
        elif kind=="software":m.sign(-.4,.75,h-.7,"code",DARK)
        elif kind=="social_network":
            m.hall(-2,-1,1.2,1.6,1.4,CREAM,GLASS);m.sign(-.4,.75,h-.2,"link","#326b9a")
        elif kind in ["stock_broker","trade_desk"]:
            m.sign(-.4,.75,h-.2,"chart",DARK)
            if kind=="stock_broker":m.cylinder(-.4,-.4,h,.7,.7,GOLD,label="exchange dome")
        elif kind=="hotel":m.sign(-.4,.75,h-.2,"H",DARK)
        elif kind=="hq":
            m.cylinder(-.4,-.4,h,1.45,.2,DARK,label="helipad")
            for xx in [-.8,0]:m.beam((xx,-1,h+.23),(xx,.3,h+.23),.13,CREAM)
            m.beam((-.8,-.3,h+.23),(0,-.3,h+.23),.13,CREAM)
    elif kind in HALLS:
        h=1.8+n*.35;w=3+n*.25
        color="#bbc4bc" if kind not in ["steel_mill","arms_plant","newspaper"] else "#aa8069"
        m.hall(-.6,-.5,w,2.3,h,color,DARK,kind in ["textile_mill","aircraft_plant"])
        if n>=1:m.hall(1.8,-.5,1.5,2.3,1.7,color,DARK)
        if n>=2:m.hall(-.7,1.5,3,1.2,1.3,color,DARK)
        if kind=="eshop":
            m.vehicle(1.2,1.5);m.box(-1,1.5,0,.8,.8,.8,GOLD,label="parcel")
            m.sign(-.6,.7,h-.3,"banner",GOLD,2,1)
        elif kind=="logistics_hub":
            for x in [-1.8,.4]:m.box(x,1,0,1,.6,.4,DARK,label="loading ramp");m.vehicle(x,1.7,RED,True)
        elif kind=="warehouse":
            # External ribbed high-bay volume; no exposed interior.
            m.box(-.6,-.5,h,2.8,2.1,1.7,CREAM,DARK,"high-bay warehouse")
            for x in [-1.7,-.9,-.1,.7]:m.box(x,.59,0,.12,.08,h+1.7,GOLD,label="facade rib")
        elif kind=="data_center":
            for x in [-1.5,-.1]:m.hvac(x,-.4,h)
            m.box(-.6,.68,.3,2.4,.12,.4,"#4b9297",label="cooling facade")
        elif kind=="auto_plant":m.sign(-.6,.7,h-.1,"car",RED);m.vehicle(.5,1.7,RED)
        elif kind=="chip_fab":
            m.box(-.6,-.5,h,2.2,1.5,.9,CREAM,label="sealed cleanroom services")
            for x in [-1.4,-.4,.6]:m.stack(x,-.6,h+.9,1,CREAM)
        elif kind=="electronics_plant":
            m.sign(-.6,.7,h-.2,"chip",GREEN)
            for x in [-1.2,.1]:m.box(x,-.4,h,.65,1,.45,GLASS,label="sawtooth rooflight")
        elif kind=="arms_plant":m.sign(-.6,.7,h-.1,"shield","#67754d");m.box(1,1.6,0,1,.8,.5,GREEN,label="ammo crate")
        elif kind=="textile_mill":
            m.stack(-1.8,-1.3,0,4.4)
            for x in [-.8,.4]:m.cylinder(x,.9,0,.45,1.1,"#c5a3a2",label="thread spool")
        elif kind=="steel_mill":
            m.stack(-1.7,-1.3,0,5);m.stack(.1,-1.3,0,4)
            m.cylinder(.4,.5,0,.65,3.3,"#826e61",label="blast furnace")
            m.box(-1,1.3,.1,1.5,.5,.4,"#ef943d",label="hot steel")
        elif kind=="pharma_lab":m.sign(-.6,.7,h,"cross",CREAM);m.hvac(.3,-.4,h)
        elif kind in ["chem_plant","oil_refinery","gas_works"]:
            if kind=="oil_refinery":
                for x in [-1.4,-.2]:m.cylinder(x,-.4,h,.3,3.3,CREAM,label="distillation column")
                m.cylinder(1.1,1,0,.85,1.6,CREAM,label="oil tank")
            elif kind=="chem_plant":
                for x in [-1.1,.3]:m.cylinder(x,-.3,h,.55,1.7,CREAM,label="process vessel")
                m.beam((-1.1,-.3,h+1),(.3,-.3,h+1),.16,GOLD)
            else:
                m.cylinder(1,.7,0,1.1,1.8,"#a2b7aa",label="gas holder")
                m.stack(-1.4,-.7,h,2.3,DARK)
        elif kind=="power_coal":
            m.stack(-1.3,-.6,h,3.4);m.stack(.2,-.6,h,2.8)
            m.cylinder(.3,1.4,0,1.2,1,DARK,0,"coal pile")
        elif kind=="gas_plant":
            for x in [-1.5,0]:m.box(x,.6,0,.9,1.1,1.4,"#8fadb1",label="turbine enclosure");m.stack(x,-.5,h,2,CREAM)
        elif kind=="aircraft_plant":m.plane(0,1.4)
        elif kind=="newspaper":m.sign(-.6,.7,h-.3,"news",CREAM);m.stack(-1.7,-.7,h,1.9)
        elif kind=="tv_station":
            for x in [-1.2,.4]:
                m.cylinder(x,-.4,h,.25,.45,CREAM,.75,"satellite dish")
                m.beam((x,-.4,h+.4),(x+.5,-.4,h+1.3),.1,CREAM)
        elif kind=="telecom":
            m.truss(-.5,-.4,h+3.7,CREAM)
            for x in [-1.1,.1]:m.box(x,-.4,h+2,.3,.4,1,GOLD,label="antenna panel")
        elif kind=="construction_co":m.crane(-.3,-.6,5.5);m.box(.2,1.3,0,1.4,1,.7,RED,label="building materials")
    elif kind in SHOPS:
        h=(3.6 if kind=="hospital" else 1.7)+n*.45
        w=3.2 if kind in ["hospital","supermarket","university"] else 2.5
        x,y=-.5,-.4
        roof=RED if kind in ["bakery","restaurant","cafe","offshore","real_estate","school_primary"] else DARK
        m.hall(x,y,w,2.2,h,CREAM,roof,roof==RED)
        if n>=1:m.hall(1.5,-.5,1.3,2,1.7,CREAM,roof,roof==RED)
        if n>=2:m.hall(-.6,1.5,2.6,1.1,1.3,CREAM,roof)
        if kind in ["clinic","hospital"]:
            m.sign(-.5,.8,h-.3,"cross",CREAM)
            if kind=="hospital":m.hall(-2,-1.1,1.2,2,3.4,CREAM,DARK)
        elif kind=="bakery":m.sign(-.5,.8,h-.1,"bread",RED);m.stack(-1.4,-.7,h,1.6)
        elif kind=="restaurant":
            m.box(-.5,1.1,1.1,2.8,1,.25,RED,label="terrace canopy")
            for xx in [-1.4,.4]:m.box(xx,1.7,0,.6,.6,.6,CREAM,label="terrace table")
            m.stack(-1.5,-.8,h,2.2)
        elif kind=="cafe":
            m.cylinder(.8,1.7,1,.9,.3,CREAM,0,"parasol");m.box(.8,1.7,0,.1,.1,1,CREAM)
            m.sign(-.5,.8,h-.1,"cup",GOLD)
        elif kind=="supermarket":m.box(-.5,.8,h,3.4,.25,.8,GREEN,label="shop sign")
        elif kind=="gym":
            m.beam((-1.4,.7,h+.7),(.5,.7,h+.7),.15,DARK)
            for xx in [-1.4,.5]:m.box(xx,.7,h,.4,.4,1.4,DARK,label="dumbbell")
        elif kind=="auto_service":m.sign(-.5,.8,h-.1,"car",DARK);m.vehicle(0,1.5,GOLD)
        elif kind=="real_estate":
            m.box(.8,1.1,0,.12,.12,2.8,DARK);m.sign(.8,1.1,1.7,"PREDAJ",RED,2.8,1.1)
        elif kind=="offshore":
            m.box(.8,1.5,0,1.7,.9+n*.5,.1,GLASS,label="pool terrace")
            m.beam((1.5,-.2,0),(1.3,-.2,4),.18,"#99835f")
            for dx,dy in [(-1,0),(1,0),(0,-1),(0,1)]:m.beam((1.3,-.2,4),(1.3+dx,-.2+dy,3.5),.28,GREEN)
        elif kind=="casino":m.cylinder(-.5,-.4,h,.95,.7,GOLD,label="casino crown");m.sign(-.5,.8,h,"coin",RED)
        elif kind=="pmc_unit":m.sign(-.5,.8,h,"shield",GREEN)
        elif kind in ["bank","university"]:
            for xx in [-1.5,-.5,.5]:m.cylinder(xx,1,0,.18,h,CREAM,label="portico column")
            m.roof(-.5,.8,h,3,1.3,CREAM)
            if kind=="bank":m.sign(-.5,.85,h+.3,"coin",DARK)
            else:m.cylinder(-.5,-.4,h,.8,1,CREAM,.2,"university cupola")
        elif kind=="school_primary":
            m.beam((1,.8,0),(1,.8,3.5),.09,CREAM);m.box(1.45,.8,3,.9,.1,.5,GOLD,label="school flag")
            m.box(-1.1,1.6,0,.8,.7,.5,RED,label="playground")
        elif kind=="school_high":m.box(-.5,-.4,h,1.2,1.2,1.4,CREAM,label="clock tower");m.sign(-.5,.3,h+.2,"H",DARK,1.7,1.3)
        elif kind=="corp_academy":m.sign(-.5,.8,h,"code",GREEN);m.box(.5,-.5,h,1,1,.7,GLASS,label="training wing")
    elif kind in ["wheat_farm","coffee_farm","livestock"]:
        m.box(0,.3,0,4+n*.8,2.8+n*.4,.12,"#93985b",label="field")
        m.hall(-1,-.8,2,1.8,1.5,RED,RED,True)
        for i in range(3+n):
            xx=-1.8+i*.8
            if kind=="wheat_farm":m.box(xx,1,.15,.25,1.6,.25,GOLD,label="wheat row")
            elif kind=="coffee_farm":m.cylinder(xx,1,.1,.4,.7,GREEN,.3,"coffee bush")
            else:m.box(xx,1,.2,.55,.35,.5,CREAM,label="livestock")
        if kind=="wheat_farm":m.cylinder(.7,-.8,0,.6,2.9+n*.6,CREAM,label="grain silo")
        elif n>=1:m.hall(1.5,-.8,1.5,1.8,1.7,RED,RED,True)
        if n>=2:m.cylinder(2.1,.2,0,.5,2.5,CREAM)
    elif kind in ["oil_well","gas_well","coal_mine","iron_mine","copper_mine"]:
        m.hall(-1,-1,2,1.4,1.2,CREAM,DARK)
        if n>=1:m.hall(1.2,-1,1.5,1.5,1.4,CREAM,DARK)
        if n>=2:m.hall(1.4,1.1,1.5,1.4,1.7,CREAM,DARK)
        if kind=="oil_well":
            m.truss(-.7,.5,3.2,DARK);m.beam((-2,.5,3.5),(.8,.5,4.2),.25,GOLD)
            m.box(-2,.5,2.5,.45,.4,1.1,GOLD);m.beam((-2,.5,0),(-2,.5,3.2),.08,DARK)
        elif kind in ["gas_well","coal_mine"]:
            m.truss(-.3,.4,4.3+n*.4,CREAM if kind=="coal_mine" else GOLD)
            if kind=="gas_well":
                m.beam((-.3,.4,.5),(1.7,.4,.5),.22,GOLD);m.beam((1.7,.4,.5),(1.7,1.4,.5),.22,GOLD)
                m.box(1.4,.4,.2,.3,.3,.6,RED,label="valve")
            else:
                z=4.3+n*.4
                m.face([(-.3+.6*math.cos(i*math.tau/12),.65,z+.6*math.sin(i*math.tau/12)) for i in range(12)],shade(DARK,1),.1)
                m.beam((-.85,.67,z),(.25,.67,z),.09,CREAM)
                m.beam((-.3,.67,z-.55),(-.3,.67,z+.55),.09,CREAM)
                m.parts.append(dict(kind="vertical winding wheel",center=[-.3,.65,z],size=[1.2,.1,1.2]))
                m.cylinder(-1.5,1.4,0,1,1.1,DARK,0,"coal pile")
        else:
            color="#ad7354" if kind=="iron_mine" else "#ca9360"
            for i in range(3):m.cylinder(-.5,.8,i*.25,1.6-i*.35,.25,color,label="open pit terrace")
            if kind=="copper_mine":m.crane(1,-.7,3.2+n*.6)
            else:m.beam((-1,.9,1),(1.6,-.8,2.5),.22,DARK)
    elif kind=="nuclear_plant":
        m.hall(-1.3,-.2,2.3,1.8,1.6,CREAM,DARK)
        m.cylinder(-1.3,-.2,1.6,.75,.9,CREAM,.35,"reactor containment dome")
        m.cooling(.8,-.7)
        if n>=1:m.cooling(-1.2,1.8)
        if n>=2:m.hall(1.7,-1.1,1.5,1.8,2,CREAM,DARK);m.cooling(1.8,1.2)
    elif kind=="solar_plant":
        for i in range(level+1):
            for j in range(2):
                x=-1.5+i*1.4;y=-1+j*1.7
                m.box(x,y,0,.15,.15,.7,DARK)
                m.face([(x-.55,y-.6,1),(x+.55,y-.6,1),(x+.55,y+.6,.6),(x-.55,y+.6,.6)],shade("#356ca1",1))
                m.beam((x,y-.6,1.03),(x,y+.6,.63),.04,CREAM)
        m.hall(-1.7,-2,1.2,.8,1,CREAM,DARK)
    elif kind in ["cargo_port","port","shipyard"]:
        m.box(0,.5,0,4.5+n*.6,3.5,.08,"#426e83",label="harbor water")
        m.box(-.5,-.8,.1,3.6+n*.5,1.4,.3,CREAM,label="quay")
        m.crane(-.6,-.7,4+ n*.45)
        if kind!="port":
            m.box(.2,1.3,.2,3.8,1.2,.55,RED,DARK,label="ship hull")
            m.box(1.5,1.3,.75,.6,1,.9,CREAM,label="ship bridge")
            m.box(-.5,1.3,.75,1.5,.9,.6,GREEN,label="deck containers")
        if kind=="cargo_port":
            for i,c in enumerate([RED,GOLD,GREEN][:level+1]):m.box(-1+i*.85,-.8,.4,.7,.9,.6,c,label="container")
        elif kind=="shipyard":m.hall(-1.8,-1.4,1.5,1.4,2.3,CREAM,DARK);m.crane(1.4,-.6,3.7)
        elif n>=1:m.crane(1.3,-.7,3.5)
    elif kind in ["airport","airline"]:
        m.box(0,.7,0,4.4+n*.5,2.6,.1,DARK,label="apron")
        m.hall(-.8,-1,2.4+n*.5,1.3,1.3+n*.3,CREAM,GLASS)
        if kind=="airline":m.plane(1.4,1.6,0,True)
        else:
            m.box(1.4,-1,0,.65,.65,3.2+n*.5,CREAM,label="control tower")
            m.box(1.4,-1,3.2+n*.5,1.1,1.1,.5,GLASS)
            for x in [-1.5,-.3,.9]:m.box(x,1,.11,.6,.1,.03,CREAM,label="runway marking")
        if n>=2:m.hall(-1.2,1.8,2.6,.7,1.1,CREAM,GLASS)
    elif kind=="highway":
        m.box(0,0,1,4.3+n*.6,1.7+n*.3,.3,DARK,label="bridge deck")
        for x in [-1.6,1.6]:m.box(x,0,0,.4,1.3,1,CREAM,label="bridge pier")
        for x in [-1.5,-.3,.9]:m.box(x,0,1.31,.6,.1,.03,CREAM)
        if n>=1:m.box(0,1.8,1,4.8,1,.3,DARK,label="parallel carriageway")
        if n>=2:m.beam((-2,-.8,1.3),(2,-.8,3),.13,GOLD)
    else:raise ValueError("Unmapped type "+kind)
    return m


def main():
    from propose_towers import designs
    approved_towers,approved_projection=designs()
    OUT.mkdir(parents=True,exist_ok=True)
    names={r['id']:r['name'] for r in json.loads((ROOT/'data/industries.json').read_text())}
    names.update(bank="Banka",hq="Centrála",port="Prístavný žeriav",highway="Diaľnica")
    records=[]
    for kind,name in names.items():
        family=approved_towers.get(kind) or [building(kind,level) for level in (1,2,3)]
        # Fit the whole FAMILY once, never each level separately. A given wall or
        # vehicle keeps exactly the same pixel scale and ground anchor on upgrade.
        raw=[((x-y)*5.3,(x+y)*2.65-z*5.3) for m in family for x,y,z in m.points]
        left,right=min(p[0] for p in raw),max(p[0] for p in raw)
        top,bottom=min(p[1] for p in raw),max(p[1] for p in raw)
        scale=min(58/(right-left),60/(bottom-top))
        projection=(scale,32-(left+right)*scale/2,62-bottom*scale)
        if kind in approved_towers:projection=approved_projection
        for level,m in enumerate(family,1):
            m.projection=projection
            im=m.render();filename=f"{kind}_{level}.png"
            im.save(OUT/filename)
            lo=[min(p[i] for p in m.points) for i in range(3)]
            hi=[max(p[i] for p in m.points) for i in range(3)]
            records.append(dict(id=kind,name=name,level=level,file=filename,parts=m.parts,
                                bounds=[lo,hi],projection=projection,pixel_bounds=im.getbbox(),sha256=hashlib.sha256(im.tobytes()).hexdigest()))
    (OUT/'manifest.json').write_text(json.dumps(dict(author="Original procedural artwork for Projekt-47",license="LicenseRef-Projekt47-Original",size=[64,72],anchor=[32,62],models=records),ensure_ascii=False,indent=2)+'\n')
    print(f"Generated {len(records)} original Atlas pixel models")
    drafts=ROOT/'docs/atlas-levels/proposals'
    drafts.mkdir(parents=True,exist_ok=True)
    for kind in ['crude_oil','fuel','finance','pmc','weapons','arms','ai_services','electronics']:
        m=Model()
        if kind=='crude_oil':
            m.cylinder(0,0,0,2,2.7,CREAM,label='cylindrical crude oil storage')
            m.cylinder(0,0,2.7,1.8,.1,DARK,label='floating roof')
            m.beam((1.6,1.4,0),(1.6,1.4,2.8),.1,GOLD)
        elif kind=='fuel':
            m.box(0,0,0,2,1.2,3.5,CREAM,label='modern fuel dispenser')
            m.box(0,.65,2.2,1.5,.1,.9,DARK,label='display')
            m.box(0,0,3.5,2.2,1.4,.6,GREEN)
            for a,b in [((1,0,3),(1.8,0,3)),((1.8,0,3),(1.8,0,.6)),((1.8,0,.6),(1.1,0,.6)),((1.1,0,.6),(1.1,0,1.8))]:m.beam(a,b,.12,DARK)
            m.box(1.1,0,1.7,.3,.3,.8,GOLD,label='fuel nozzle')
        elif kind=='finance':
            for x,y,h in [(-1,0,1.4),(1,0,2.2),(0,1.4,.6)]:
                for z in range(round(h/.3)):m.cylinder(x,y,z*.3,.8,.2,GOLD,label='coin')
        elif kind=='pmc':m.sign(0,0,0,'shield',GREEN,3.6,3.3)
        elif kind=='weapons':
            m.box(0,0,1,3,.45,.5,DARK,label='rifle receiver')
            m.box(-1.7,0,.8,1.2,.6,.7,'#896e4f',label='stock')
            m.beam((1,0,1.3),(2.4,0,1.3),.13,DARK)
            m.box(.2,0,.1,.45,.4,1,DARK,label='magazine')
        elif kind=='arms':
            m.box(0,0,0,3,2,1.7,'#707e50',label='ammo crate')
            for x in [-1,1]:m.box(x,0,1.7,.18,2.1,.1,GOLD,label='crate strap')
        elif kind=='ai_services':
            for x,y,z in [(-1,0,1),(0,0,2),(1,0,1)]:m.cylinder(x,y,z,.85,.9,CREAM,.5,'cloud node')
            for x in [-1,0,1]:m.box(x,1,0,.7,.6,1.1,DARK,label='server');m.box(x,1.33,.6,.4,.05,.2,GREEN)
        else:
            m.box(0,0,0,3.5,2.8,.2,GREEN,label='PCB assembly')
            m.box(0,0,.2,1.2,1,.35,DARK)
            for x in [-1,1]:m.cylinder(x,.8,.2,.2,.5,CREAM)
        m.render().save(drafts/(kind+'.png'))


if __name__=='__main__':main()
