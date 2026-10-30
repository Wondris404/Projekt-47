#!/usr/bin/env python3
"""Bake Natural Earth real urban footprints; requires shapely >= 2.1.
Usage: python tools/atlas/build_urban_footprints.py /path/ne_10m_urban_areas.geojson
Source: https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_urban_areas.geojson
No population radius, minimum pixel size or city-specific scaling.
"""
import hashlib
import json
import math
from pathlib import Path
import sys
from shapely import constrained_delaunay_triangles
from shapely.geometry import shape, Point

ROOT = Path(__file__).resolve().parents[2]
source = Path(sys.argv[1])
features = json.loads(source.read_text())['features']
map_data = json.loads((ROOT / 'data/map.json').read_text())
w, h = map_data['w'], map_data['h']
tiles = {}
original_area = simplified_area = 0.0
max_error = 0.0
holes = 0
city_samples = {name: Point(lon,lat) for name,lon,lat in [
    ('Bratislava',17.1067,48.1482), ('Vienna',16.3738,48.2082),
    ('Paris',2.3522,48.8566), ('Tokyo',139.6917,35.6895)]}
samples = {}

def project(x,y):
    return (round((x+180)/360*(w-1),5),round((90-y)/180*(h-1),5))

for f in features:
    original = shape(f['geometry'])
    poly = original.simplify(.002, preserve_topology=True)
    assert poly.is_valid
    original_area += original.area
    simplified_area += poly.area
    holes += len(poly.interiors)
    triangles = constrained_delaunay_triangles(poly)
    error = abs(sum(t.area for t in triangles.geoms)-poly.area)
    max_error = max(max_error,error)
    assert error < 1e-8
    for name,p in city_samples.items():
        if poly.covers(p):
            x0,y0,x1,y1=poly.bounds
            samples[name] = {'lon_lat_bounds':list(poly.bounds), 'width_km':round((x1-x0)*111.195*math.cos(math.radians(p.y)),2),'height_km':round((y1-y0)*111.195,2),'source_area_sqkm':f['properties']['area_sqkm']}
    for tri in triangles.geoms:
        pts=[project(x,y) for x,y in list(tri.exterior.coords)[:3]]
        center=tri.centroid
        key=(math.floor((center.x+180)/5),math.floor((90-center.y)/5))
        tile=tiles.setdefault(key,{'vertices':[], 'indices':[], '_lookup':{}})
        for pt in pts:
            if pt not in tile['_lookup']:
                tile['_lookup'][pt]=len(tile['vertices'])//2
                tile['vertices'].extend(pt)
            tile['indices'].append(tile['_lookup'][pt])

for tile in tiles.values():
    del tile['_lookup']
    xs,ys=tile['vertices'][::2],tile['vertices'][1::2]
    tile['bounds']=[min(xs),min(ys),max(xs)-min(xs),max(ys)-min(ys)]
out={'source':'Natural Earth 1:10m urban areas', 'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(), 'map_size':[w,h], 'simplify_degrees':.002, 'tiles':[tiles[key] for key in sorted(tiles)]}
(ROOT/'data/atlas/urban_footprints.json').write_text(json.dumps(out,separators=(',',':'))+'\n')
audit={'source_features':len(features),'holes_preserved':holes,'tiles':len(tiles),'vertices':sum(len(t['vertices'])//2 for t in tiles.values()),'triangles':sum(len(t['indices'])//3 for t in tiles.values()),'area_ratio_after_simplification':simplified_area/original_area,'max_triangulation_area_error_degrees2':max_error,'samples':samples,'source_sha256':out['source_sha256']}
(ROOT/'data/atlas/urban_footprints_audit.json').write_text(json.dumps(audit,indent=2)+'\n')
print(json.dumps(audit,indent=2))
