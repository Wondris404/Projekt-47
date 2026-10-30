#!/usr/bin/env python3
"""Original 32px pixel icons and 9-slice bronze chrome. No external artwork."""
from pathlib import Path
from PIL import Image, ImageDraw
import random
OUT=Path(__file__).resolve().parents[2]/'assets/ui/strategic'
OUT.mkdir(parents=True,exist_ok=True)
G='#d6b876'; HI='#f5dfaa'; DARK='#665039'; EDGE='#211f1b'; RED='#d57869'; WHITE='#ded9c7'

def icon(name,paint):
 im=Image.new('RGBA',(32,32)); d=ImageDraw.Draw(im); paint(d); im.save(OUT/(name+'.png'))

def coin(d,red=False):
 c=RED if red else G
 d.ellipse((4,5,26,27),fill=EDGE)
 d.ellipse((5,4,26,25),fill=DARK)
 d.ellipse((5,3,26,24),fill=c)
 d.arc((7,5,24,22),180,310,fill=HI,width=2)
 d.line([(20,8),(14,8),(11,11),(11,17),(14,20),(20,20)],fill=EDGE,width=2)
 d.line((8,12,18,12),fill=EDGE,width=2);d.line((8,16,18,16),fill=EDGE,width=2)
icon('money',lambda d:coin(d))
def debt(d):
 coin(d,True);d.rectangle((24,16,27,25),fill=HI);d.polygon([(20,23),(30,23),(25,29)],fill=HI)
icon('debt',debt)
def podium(d):
 d.ellipse((12,2,19,9),fill=HI);d.rectangle((9,10,22,17),fill='#aeb8bc')
 d.rectangle((6,16,25,19),fill=G);d.polygon([(8,20),(23,20),(21,28),(10,28)],fill=DARK)
 d.rectangle((8,28,24,30),fill=G);d.line((22,16,25,10),fill=HI,width=2)
icon('influence',podium)
def heart(d):
 d.polygon([(3,7),(7,3),(12,3),(16,7),(20,3),(25,3),(29,7),(29,14),(16,28),(3,14)],fill=EDGE)
 d.polygon([(5,8),(8,5),(12,5),(16,10),(20,5),(24,5),(27,8),(27,13),(16,25),(5,13)],fill=RED)
 d.line([(7,10),(9,7),(12,7)],fill='#efb5a0',width=2)
icon('popularity',heart)
def flag(d):
 d.rectangle((5,3,7,28),fill=G);d.ellipse((4,1,8,5),fill=HI)
 d.polygon([(8,4),(17,4),(20,7),(29,7),(26,14),(17,14),(14,11),(8,11)],fill='#8ca4ac')
 d.line((8,5,16,5),fill='#d1dad6',width=2);d.rectangle((2,28,12,30),fill=DARK)
icon('states',flag)
def people(d):
 for x,y in [(4,9),(21,9),(12,4)]:
  d.rectangle((x,y,x+5,y+6),fill=HI);d.rectangle((x-2,y+8,x+7,y+17),fill='#9ca9a7')
icon('employees',people)
def clock(d):
 d.ellipse((2,2,29,29),fill=DARK);d.ellipse((4,4,27,27),fill=G);d.ellipse((6,6,25,25),fill='#252d30')
 for p in [(15,7,16,9),(15,22,16,24),(7,15,9,16),(22,15,24,16)]:d.rectangle(p,fill=HI)
 d.line([(16,10),(16,16),(21,19)],fill=HI,width=2)
icon('clock',clock)
icon('pause',lambda d:(d.rectangle((8,7,12,25),fill=HI),d.rectangle((20,7,24,25),fill=HI)))
DIGITS={'1':['010','110','010','010','111'],'4':['101','101','111','001','001'],'0':['111','101','101','101','111'],'x':['000','101','010','101','000']}
def speed(d,s):
 d.polygon([(4,4),(11,8),(4,12)],fill=G)
 x=5 if len(s)==2 else 2
 for c in s:
  for y,line in enumerate(DIGITS[c]):
   for xx,b in enumerate(line):
    if b=='1':d.rectangle((x+xx*2,16+y*2,x+xx*2+1,17+y*2),fill=HI)
  x+=8
for s in ['1x','4x','10x']:icon('speed_'+s,lambda d,s=s:speed(d,s))
def chrome(name,size):
 im=Image.new('RGBA',(size,size));d=ImageDraw.Draw(im);rng=random.Random(47)
 for y in range(size):
  for x in range(size):
   n=rng.choice([-1,0,0,1]);v=34-int(y/size*10)+n
   im.putpixel((x,y),(v,v+3,v+4,255))
 d.rectangle((0,0,size-1,size-1),outline=EDGE,width=2)
 d.rectangle((2,2,size-3,size-3),outline=DARK,width=2)
 d.line((4,4,size-5,4),fill='#a18b62');d.line((4,4,4,size-5),fill='#79684d')
 d.line((4,size-5,size-5,size-5),fill='#3d342b');d.line((size-5,4,size-5,size-5),fill='#3d342b')
 for x,y in [(3,3),(size-5,3),(3,size-5),(size-5,size-5)]:
  d.rectangle((x,y,x+1,y+1),fill=G)
 im.save(OUT/(name+'.png'))
chrome('metric_frame',32);chrome('panel_frame',64)
print('Generated',len(list(OUT.glob('*.png'))),'original assets')
