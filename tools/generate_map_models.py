"""Deterministic original pixel art for Atlas only. Requires Pillow; no UI assets touched."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/map_models'
OUT.mkdir(exist_ok=True)

def model(kind):
    im = Image.new('RGBA', (64, 72)); d = ImageDraw.Draw(im)
    def rect(x,y,w,h,c): d.rectangle((x,y,x+w-1,y+h-1),fill=c)
    def line(points,c,w=1): d.line(points,fill=c,width=w)
    def poly(points,c): d.polygon(points,fill=c)
    def box(x,y,w=18,dep=9,h=18,wall='#c4beb0',roof='#707985'):
        poly([(x-w,y),(x,y+dep),(x+w,y),(x,y-dep)],'#263438')
        poly([(x-w,y-h),(x,y-h+dep),(x,y+dep),(x-w,y)],wall)
        poly([(x,y-h+dep),(x+w,y-h),(x+w,y),(x,y+dep)],'#717e84')
        poly([(x-w,y-h),(x,y-h-dep),(x+w,y-h),(x,y-h+dep)],roof)
    def windows(x,y,n=3):
        for i in range(n): rect(x+i*5,y+i*2,2,3,'#b4e3ef')
    def chimney(x,y,h=24):
        rect(x,y-h,5,h,'#944e3c');rect(x,y-h,5,4,'#d9d0bf');rect(x+1,y-h-5,5,4,'#c2ced1')
    def cross(x,y): rect(x,y,4,12,'#d54e4e');rect(x-4,y+4,12,4,'#d54e4e')
    poly([(5,57),(31,68),(61,55),(34,44)],'#27383280')
    if kind in ['wheat_farm','coffee_farm','livestock']:
        poly([(3,44),(30,32),(61,47),(33,62)],'#8e9650')
        for i in range(5): line([(9+i*6,43-i*2),(36+i*5,57-i*3)],'#d4b75e',2)
        box(38,46,12,6,13,'#b14c40','#7d342e')
        if kind=='coffee_farm':
            for x,y in [(13,44),(21,48),(28,52)]: rect(x,y,7,5,'#326a36');rect(x+2,y+2,2,2,'#ae4530')
        elif kind=='livestock':
            for x,y in [(12,45),(21,51)]: rect(x,y,8,4,'#e6e0cc');rect(x+2,y,2,2,'#393b38');rect(x,y+4,2,3,'#d8cfb0')
        else: rect(48,24,7,21,'#c3b9a1');rect(47,23,9,4,'#ded6bd')
    elif kind in ['oil_well','gas_well']:
        box(43,52,12,5,10,'#a59876','#6f7277')
        if kind=='oil_well':
            line([(14,54),(22,25),(29,54)],'#38494d',3);line([(9,27),(36,20)],'#d5a53a',4);rect(6,25,6,12,'#b17c2e');line([(10,35),(10,53)],'#c2ad7d',2)
        else:
            line([(17,53),(17,28),(29,28)],'#dbb65d',4);line([(10,43),(29,43)],'#deb563',3);rect(12,35,11,3,'#b9473f');rect(24,22,5,9,'#b9473f')
    elif kind in ['coal_mine','iron_mine','copper_mine']:
        colors={'coal_mine':'#343d41','iron_mine':'#9a644e','copper_mine':'#c3884b'}
        poly([(3,55),(15,40),(27,53),(39,46),(52,58)],colors[kind]);box(39,48,12,6,16,'#a89a83','#5c656a')
        line([(14,50),(22,18),(31,46)],'#3d4a4e',3);line([(14,34),(29,34)],'#a19a80',2);d.ellipse((17,12,28,23),outline='#d2c1a0',width=2);line([(24,22),(46,43)],'#56646a',3)
    elif kind in ['nuclear_plant','power_coal','gas_plant','solar_plant']:
        if kind=='solar_plant':
            for x,y in [(16,40),(36,49),(37,33)]:
                poly([(x-11,y),(x,y-6),(x+11,y),(x,y+6)],'#284b7a');line([(x-8,y),(x+8,y)],'#699cc4');line([(x,y-4),(x,y+4)],'#699cc4')
        else:
            box(32,52,23,10,13,'#b1b3ab','#727c80')
            if kind=='nuclear_plant':
                for x,y in [(18,48),(42,52)]:
                    poly([(x-8,y),(x-5,y-12),(x-6,y-24),(x+6,y-24),(x+5,y-12),(x+8,y)],'#d5d8cc');rect(x-6,y-25,12,3,'#8e9b9a');rect(x-4,y-32,8,5,'#dde8df');rect(x-2,y-37,10,4,'#c7d9d3')
            elif kind=='power_coal': chimney(18,42,31);chimney(37,43,25);poly([(5,56),(15,46),(25,58)],'#333b3c')
            else:
                for x in [15,27,39]: box(x,48,7,4,7,'#9da8a9','#cbd1c6')
                chimney(48,45,28)
    elif kind in ['cargo_port','shipyard','airport','airline','aircraft_plant']:
        if kind in ['cargo_port','shipyard']:
            poly([(3,50),(33,36),(62,49),(32,65)],'#395d73');rect(6,48,49,4,'#8b8c7f')
            line([(21,51),(21,19),(48,26)],'#e1b34c',3);line([(44,26),(44,40)],'#555d59',1)
            poly([(16,55),(23,61),(48,53),(51,48),(25,51)],'#c6c3ad');rect(35,48,7,4,'#9e4940')
            if kind=='cargo_port':
                for x,y,c in [(7,40,'#b55a41'),(15,44,'#486d89'),(30,37,'#c6a646')]: box(x+5,y,6,3,5,c,c)
            else: box(47,43,13,6,17,'#a8b1ae','#5f6d73');line([(10,48),(10,26),(32,22)],'#daa748',3)
        else:
            poly([(3,52),(46,31),(61,39),(17,60)],'#515f64');line([(10,52),(52,33)],'#e4dbc1',1)
            box(43,49,15,7,11,'#aeb9b6','#7b8e93');rect(51,20,5,20,'#a6b7b7');rect(47,18,12,6,'#627c8a')
            if kind=='aircraft_plant':box(23,48,18,9,20,'#c0c4b8','#6b8690')
            line([(13,45),(37,35)],'#ecebd7',3);line([(25,34),(24,48)],'#ecebd7',3);line([(13,41),(17,49)],'#d4bf8e',2)
    elif kind in ['hospital','clinic','school_primary','school_high','university','corp_academy']:
        edu=kind.startswith('school') or kind in ['university','corp_academy']
        box(32,51,23,10,23 if kind=='hospital' else 18,'#d2c5a2' if edu else '#d9ded5','#a65f49' if edu else '#739698')
        windows(12,35);windows(35,38)
        rect(27,43,8,14,'#536b73')
        if not edu:
            if kind=='hospital': box(40,37,10,5,15,'#d4dfd9','#72999d')
            cross(26,24 if kind=='clinic' else 16)
        elif kind=='university':
            poly([(18,26),(32,17),(46,26)],'#d5d0b3')
            for x in [21,28,35,42]:rect(x,28,3,14,'#e2dabe')
        elif kind=='corp_academy': rect(23,23,18,6,'#587f98');line([(32,12),(32,23)],'#b9bda4',2)
        elif kind=='school_primary':
            line([(13,17),(13,29)],'#d9d5b5',1);poly([(14,18),(24,20),(14,23)],'#d9a542');rect(5,49,7,7,'#cf8c4c')
        else:rect(27,19,10,8,'#d2c3a0');d.ellipse((30,20,35,25),fill='#52676b');rect(50,45,6,11,'#4a7a48')
    elif kind in ['bank','finance_office','insurance','invest_fund','stock_broker','offshore']:
        box(32,52,22,10,23,'#c4c7b7','#7c9192')
        if kind=='bank':
            poly([(10,29),(32,16),(54,29)],'#e3dbc2')
            for x in [14,24,34,44]:rect(x,31,4,16,'#e5ddc8')
            rect(27,42,8,15,'#3d565e')
        else:
            levels={'finance_office':2,'insurance':3,'invest_fund':4,'stock_broker':5,'offshore':2}[kind]
            for i in range(levels): windows(14,29+i*5,4)
            if kind=='offshore':line([(49,54),(49,27)],'#967a4c',2);line([(40,29),(49,24),(58,28)],'#427b51',3)
            elif kind=='stock_broker':line([(25,24),(30,18),(35,22),(42,12)],'#72ac7d',2)
            else:rect(27,22,10,3,'#d1b963')
    elif kind in ['telecom','tv_station','software','social_network','ai_firm','data_center','ad_agency','newspaper']:
        if kind=='data_center':
            box(32,52,24,11,19,'#829293','#466575')
            for x,y in [(18,32),(29,37),(40,32)]:rect(x,y,7,5,'#c8ccbb');rect(x+2,y+1,3,3,'#5a6c70')
            windows(14,43,4)
        elif kind in ['telecom','tv_station']:
            box(33,53,20,10,16,'#b5baab','#677d86');line([(27,40),(33,8),(39,40)],'#97a4a0',2);line([(22,19),(44,19)],'#dcaa4f',2)
            if kind=='tv_station':d.ellipse((37,19,50,32),fill='#d8ddce');line([(43,25),(51,19)],'#656e6c',2)
        elif kind=='newspaper':
            box(32,52,22,10,18,'#acaa94','#687d81');rect(10,38,15,9,'#e1dfc6');line([(12,41),(23,41)],'#425b65',2);chimney(48,43,16)
        else:
            h={'software':27,'social_network':32,'ai_firm':36,'ad_agency':22}[kind]
            box(32,52,18,9,h,'#8daab1','#c9d6cb')
            for i in range(4):windows(17,52-h+5+i*5,3)
            if kind=='ai_firm':rect(29,9,7,6,'#6acac6');line([(32,5),(32,9)],'#d2cdb5')
            elif kind=='ad_agency':rect(15,20,29,9,'#d5ac53');rect(18,23,9,3,'#c65b49')
            elif kind=='social_network':rect(27,13,10,6,'#629dca')
    elif kind in ['logistics_hub','warehouse','trade_desk','eshop']:
        box(32,52,24,11,17,'#b6b4a2','#647c85');rect(13,40,9,9,'#3e535d');rect(26,45,9,9,'#3e535d')
        if kind=='logistics_hub':
            for x,y,c in [(44,48,'#a9513e'),(47,54,'#49738e'),(12,55,'#d4af50')]:box(x,y,7,3,5,c,c)
        elif kind=='warehouse':box(46,55,8,4,7,'#b88c57','#cfad71');box(9,53,6,3,6,'#b88c57','#cfad71')
        elif kind=='eshop':rect(24,25,14,6,'#deac53');rect(41,53,13,5,'#ddddca');rect(43,58,3,3,'#2c3d42');rect(51,58,3,3,'#2c3d42')
        else:line([(9,54),(9,29)],'#d3c7a5',2);poly([(10,29),(22,32),(10,36)],'#5f9a81')
    elif kind in ['cafe','restaurant','bakery','supermarket','gym','auto_service','real_estate','hotel','casino','pmc_unit']:
        h=34 if kind=='hotel' else 18
        box(32,52,22,10,h,'#d0bb94','#a65c49' if kind in ['cafe','restaurant','bakery'] else '#667f83');windows(13,52-h+6,3);rect(27,43,8,14,'#536a70')
        if kind in ['cafe','restaurant','bakery','supermarket']:
            for i in range(5):rect(10+i*4,36+i*2,4,5,'#b44f40' if i%2 else '#e8dbc0')
            if kind=='cafe':rect(46,52,11,3,'#dac7a3');rect(50,55,2,5,'#78664a')
            elif kind=='restaurant':chimney(46,32,18)
            elif kind=='bakery':rect(20,26,17,7,'#b77843');line([(22,28),(33,30)],'#edc887',2)
            else:rect(20,24,25,7,'#63a07a');rect(49,51,8,6,'#a4b5b2')
        elif kind=='hotel':
            for i in range(4):windows(14,25+i*6,3)
            rect(28,6,8,7,'#dbc47b');line([(30,7),(30,12)],'#5d7381');line([(34,7),(34,12)],'#5d7381');line([(30,10),(34,10)],'#5d7381')
        elif kind=='casino':rect(13,24,35,5,'#c79d4d');rect(27,15,8,8,'#cc5d66');rect(30,18,2,2,'#f2ddab')
        elif kind=='gym':line([(20,26),(43,26)],'#3e535e',3);rect(19,22,4,9,'#364750');rect(40,22,4,9,'#364750')
        elif kind=='auto_service':rect(12,37,14,13,'#344d58');rect(40,51,15,6,'#bf754d');rect(42,55,3,4,'#26383e');rect(51,55,3,4,'#26383e')
        elif kind=='pmc_unit':rect(21,25,20,6,'#6e794f');line([(42,53),(42,20)],'#9ca27b',2);poly([(43,20),(56,23),(43,27)],'#71834f')
        else:poly([(19,24),(32,13),(45,24)],'#b06449');rect(29,20,6,7,'#d7d1af')
    else:
        # Industrial plants: sawtooth production halls with industry-specific equipment.
        box(32,52,23,11,20,'#afa994','#6e8184')
        for x,y in [(10,30),(22,35),(34,30)]:poly([(x,y+3),(x+8,y-4),(x+8,y+7)],'#c1c0a9')
        windows(12,40,3)
        if kind in ['chem_plant','oil_refinery','gas_works','pharma_lab']:
            for x,y in [(17,36),(38,38)]:
                rect(x,y-17,9,18,'#c9d0c5');d.ellipse((x,y-20,x+8,y-15),fill='#e1e1cb');line([(x+9,y-9),(x+15,y-9),(x+15,y+6)],'#a6b4a8',2)
            if kind=='oil_refinery':chimney(49,35,27);line([(8,40),(8,16),(22,16)],'#bfaa75',2)
            elif kind=='gas_works':rect(28,10,6,22,'#8a998a');poly([(27,10),(31,1),(35,10)],'#e4a547')
            elif kind=='pharma_lab':cross(27,22)
            else:chimney(48,33,17)
        elif kind=='construction_co':line([(43,48),(43,10),(8,16)],'#e2b84f',3);line([(12,16),(12,34)],'#60675e',1)
        elif kind=='steel_mill':chimney(17,35,27);chimney(45,37,23);rect(24,39,11,6,'#d88541')
        elif kind=='auto_plant':rect(25,50,21,6,'#9d4d3d');rect(29,47,10,4,'#b2c9c6');rect(28,55,4,4,'#283c43');rect(40,55,4,4,'#283c43')
        elif kind=='arms_plant':rect(19,30,22,5,'#6f8056');line([(40,31),(53,27)],'#687a54',3)
        elif kind=='textile_mill':rect(24,29,17,9,'#c9a1a1');line([(25,31),(38,35)],'#e8d3b7',2);chimney(49,34,19)
        elif kind=='chip_fab':rect(22,24,21,13,'#527e87');rect(25,27,15,7,'#c5c7ad')
        elif kind=='electronics_plant':rect(20,27,23,12,'#4f8c77');rect(26,30,10,5,'#384c50');line([(21,29),(41,29)],'#bcbb81')
        else: raise ValueError('Unmapped industry '+kind)
    return im

if __name__ == '__main__':
    ids=[r['id'] for r in json.loads((ROOT/'data/industries.json').read_text())]+['bank']
    for kind in ids: model(kind).save(OUT/(kind+'.png'))
    print(f'Generated {len(ids)} original Atlas sprites')
