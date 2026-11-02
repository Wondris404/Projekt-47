import bpy,sys,math
argv=sys.argv[sys.argv.index('--')+1:]
src,glb,png,yaw=argv[0],argv[1],argv[2],float(argv[3])
if not src.endswith('.blend'): bpy.ops.wm.read_factory_settings(use_empty=True)
if src.endswith('.blend'): [bpy.data.objects.remove(o) for o in list(bpy.data.objects) if o.type in ('CAMERA','LIGHT')]
elif src.endswith('.fbx'): bpy.ops.import_scene.fbx(filepath=src)
elif False:
    with bpy.data.libraries.load(src) as (a,b): b.objects=a.objects
    for o in b.objects:
        if o: bpy.context.scene.collection.objects.link(o)
else: bpy.ops.import_scene.gltf(filepath=src)
import os
for m in bpy.data.materials:
    if not m.use_nodes: continue
    nt=m.node_tree
    if hasattr(m,'blend_method'): m.blend_method='OPAQUE'
    for n in nt.nodes:
        if n.type=='TEX_IMAGE' and n.image and not n.image.has_data:
            n.image.filepath=os.path.join(os.path.dirname(os.path.abspath(src)),os.path.basename(n.image.filepath.lstrip('/'))); n.image.reload()
    bs=[n for n in nt.nodes if n.type in('BSDF_PRINCIPLED','BSDF_DIFFUSE')]
    tx=[n for n in nt.nodes if n.type=='TEX_IMAGE']
    for b in bs:
        if 'Alpha' in b.inputs:
            for l in list(b.inputs['Alpha'].links): nt.links.remove(l)
        if tx and not b.inputs['Color' if 'Color' in b.inputs else 'Base Color'].links:
            nt.links.new(tx[0].outputs['Color'],b.inputs['Color' if 'Color' in b.inputs else 'Base Color'])
if glb!='-': bpy.ops.export_scene.gltf(filepath=glb,export_format='GLB',export_animations=True)
sc=bpy.context.scene
import mathutils
pts=[o.matrix_world@mathutils.Vector(c) for o in sc.objects if o.type=='MESH' for c in o.bound_box]
mn=mathutils.Vector([min(p[i] for p in pts) for i in range(3)]);mx=mathutils.Vector([max(p[i] for p in pts) for i in range(3)])
c=(mn+mx)/2;r=(mx-mn).length/2;print('BOUNDS',mn,mx)
for o in sc.objects:
    if o.type in('MESH','ARMATURE') and o.parent is None: o.rotation_euler[2]+=math.radians(yaw)
cam=bpy.data.objects.new('c',bpy.data.cameras.new('c'));sc.collection.objects.link(cam);sc.camera=cam
cam.data.type='ORTHO';cam.data.clip_end=r*20;cam.data.clip_start=r*0.01;cam.data.ortho_scale=r*2.1
d=mathutils.Vector((1,-1,1.1)).normalized()*r*4;cam.location=c+d
cam.rotation_euler=(c-cam.location).to_track_quat('-Z','Y').to_euler()
l=bpy.data.objects.new('l',bpy.data.lights.new('l','SUN'));sc.collection.objects.link(l);l.rotation_euler=(0.7,0.2,0.8);l.data.energy=4
w=bpy.data.worlds.new('w');sc.world=w;w.color=(0.6,0.6,0.6)
sc.render.engine='BLENDER_EEVEE_NEXT';sc.render.film_transparent=True
sc.render.resolution_x=sc.render.resolution_y=128;sc.render.filepath=png
bpy.ops.render.render(write_still=True)
