"""Render original Brassburrow figures into transparent top-down game sprites."""

import bpy
import math
import os
import sys
from mathutils import Vector


def arg(name, default):
    for item in sys.argv:
        if item.startswith(name + "="):
            return item.split("=", 1)[1]
    return default


OUT = arg("--out", "/tmp/brassburrow-frames")
KIND = arg("--kind", "hero")
PREVIEW = arg("--preview", "0") == "1"
os.makedirs(OUT, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def mat(name, rgb, rough=0.75, metal=0.0):
    item = bpy.data.materials.new(name)
    item.diffuse_color = (*rgb, 1)
    item.use_nodes = True
    shader = item.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*rgb, 1)
    shader.inputs["Roughness"].default_value = rough
    shader.inputs["Metallic"].default_value = metal
    return item


rust = mat("warm rust enamel", (0.61, 0.25, 0.16), 0.58)
cream = mat("cream wool", (0.92, 0.75, 0.52), 0.9)
skin = mat("mole clay", (0.69, 0.44, 0.31), 0.82)
ink = mat("ink brown", (0.09, 0.10, 0.11), 0.7)
brass = mat("brushed brass", (0.74, 0.49, 0.17), 0.42, 0.48)
sage = mat("moss green", (0.30, 0.48, 0.31), 0.86)
lime = mat("mint glass", (0.43, 0.87, 0.58), 0.25)
slate = mat("slate blue", (0.20, 0.34, 0.42), 0.7)
wood = mat("amber wood", (0.47, 0.28, 0.16), 0.82)
red = mat("beetle carapace", (0.52, 0.18, 0.15), 0.36)
white = mat("eye glint", (1.0, 0.96, 0.78), 0.2)


def empty(name, parent=None, loc=(0, 0, 0)):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.location = loc
    return obj


def sphere(name, loc, scale, material, parent=None, seg=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=max(12, seg // 2), location=(0, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.location = loc
    obj.scale = scale
    obj.data.materials.append(material)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def cube(name, loc, scale, material, parent=None, bevel=0.1):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.location = loc
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    if bevel:
        mod = obj.modifiers.new("soft worn edge", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        obj.modifiers.new("weighted normals", "WEIGHTED_NORMAL")
    return obj


def cylinder(name, loc, radius, depth, material, parent=None, vertices=20, angle=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=(0, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.location = loc
    if angle:
        obj.rotation_euler = angle
    obj.data.materials.append(material)
    obj.modifiers.new("weighted normals", "WEIGHTED_NORMAL")
    return obj


def hero():
    rig = empty("Pip root")
    torso = empty("torso motion", rig)
    sphere("quilted coat", (0, 0.03, 1.10), (0.49, 0.36, 0.63), rust, torso)
    sphere("cream collar", (0, -0.16, 1.49), (0.37, 0.28, 0.15), cream, torso)
    sphere("round head", (0, -0.09, 1.85), (0.51, 0.42, 0.45), skin, torso)
    sphere("left ear", (-0.48, 0.02, 1.88), (0.24, 0.15, 0.25), skin, torso)
    sphere("right ear", (0.48, 0.02, 1.88), (0.24, 0.15, 0.25), skin, torso)
    sphere("left ear inner", (-0.50, -0.12, 1.88), (0.14, 0.05, 0.15), rust, torso)
    sphere("right ear inner", (0.50, -0.12, 1.88), (0.14, 0.05, 0.15), rust, torso)
    sphere("muzzle", (0, -0.43, 1.69), (0.24, 0.15, 0.19), cream, torso)
    sphere("nose", (0, -0.58, 1.73), (0.09, 0.08, 0.07), ink, torso)
    for x in (-0.21, 0.21):
        sphere("dark eye", (x, -0.449, 1.94), (0.11, 0.05, 0.15), ink, torso)
        sphere("eye light", (x - 0.03, -0.498, 2.01), (0.035, 0.018, 0.04), white, torso)
        cylinder("goggle rim", (x, -0.445, 1.96), 0.16, 0.045, brass, torso, angle=(math.pi / 2, 0, 0))
    cube("helmet shell", (0, 0.03, 2.22), (0.87, 0.75, 0.24), sage, torso, 0.11)
    cube("helmet lamp", (0, -0.38, 2.19), (0.22, 0.12, 0.13), brass, torso, 0.04)
    sphere("lamp glass", (0, -0.455, 2.19), (0.08, 0.03, 0.05), lime, torso)
    cube("pack", (0, 0.36, 1.18), (0.52, 0.26, 0.62), slate, torso, 0.08)
    for z in (0.89, 1.10, 1.31):
        sphere("brass coat button", (0.10, -0.33, z), (0.035, 0.02, 0.035), brass, torso)
    cube("coat pocket", (-0.26, -0.32, 0.91), (0.26, 0.05, 0.18), wood, torso, 0.025)
    cube("helmet badge", (0.27, -0.29, 2.24), (0.13, 0.06, 0.08), brass, torso, 0.025)
    arms = []
    for side in (-1, 1):
        pivot = empty("arm pivot", torso, (side * 0.47, -0.02, 1.43))
        sphere("jacket arm", (side * 0.16, -0.03, -0.24), (0.20, 0.21, 0.37), rust, pivot)
        sphere("glove", (side * 0.20, -0.14, -0.52), (0.17, 0.16, 0.15), cream, pivot)
        arms.append(pivot)
    # The little copper hoe is worn on the right forearm.
    cylinder("tool haft", (0.66, -0.34, 0.65), 0.045, 0.76, wood, torso, angle=(0.28, 0, 0))
    cube("tool blade", (0.66, -0.48, 0.30), (0.32, 0.12, 0.22), brass, torso, 0.045)
    feet = []
    for side in (-1, 1):
        leg = empty("boot motion", rig, (side * 0.24, 0.02, 0))
        sphere("trouser", (0, 0, 0.58), (0.22, 0.24, 0.41), slate, leg)
        sphere("leather boot", (0, -0.14, 0.18), (0.26, 0.33, 0.19), wood, leg)
        cube("brass boot buckle", (0, -0.36, 0.24), (0.17, 0.06, 0.07), brass, leg, 0.01)
        feet.append(leg)
    sphere("round tail", (0, 0.44, 0.88), (0.26, 0.32, 0.23), skin, rig)
    return rig, torso, arms, feet


def shopper():
    rig = empty("market rabbit root")
    body = empty("coat bounce", rig)
    coat = mat("shopper linen", (0.70, 0.49, 0.34), 0.88)
    rose = mat("shopper bonnet", (0.69, 0.43, 0.46), 0.87)
    sphere("pear shaped cloak", (0, 0.04, 1.07), (0.50, 0.39, 0.67), coat, body)
    sphere("cream scarf", (0, -0.20, 1.48), (0.42, 0.23, 0.12), cream, body)
    sphere("rabbit head", (0, -0.10, 1.79), (0.46, 0.39, 0.44), cream, body)
    for side in (-1, 1):
        ear = sphere("upright felt ear", (side * 0.27, 0.03, 2.34), (0.17, 0.15, 0.42), cream, body)
        ear.rotation_euler.y = side * 0.14
        sphere("ear inset", (side * 0.27, -0.12, 2.35), (0.08, 0.03, 0.31), rose, body)
        sphere("button eye", (side * 0.20, -0.45, 1.86), (0.055, 0.04, 0.08), ink, body)
    sphere("muzzle", (0, -0.46, 1.66), (0.18, 0.10, 0.12), white, body)
    sphere("rose nose", (0, -0.56, 1.73), (0.065, 0.05, 0.06), rose, body)
    cube("soft bonnet", (0, 0.02, 2.08), (0.70, 0.66, 0.17), rose, body, 0.08)
    sphere("market basket", (0.53, -0.02, 0.73), (0.30, 0.26, 0.23), wood, body)
    arms = []
    for side in (-1, 1):
        arm = empty("rabbit arm", body, (side * 0.46, 0.02, 1.41))
        sphere("linen sleeve", (side * 0.16, -0.04, -0.25), (0.18, 0.20, 0.35), coat, arm)
        sphere("felt paw", (side * 0.20, -0.12, -0.49), (0.13, 0.13, 0.14), cream, arm)
        arms.append(arm)
    feet = []
    for side in (-1, 1):
        foot = empty("rabbit step", rig, (side * 0.24, 0, 0))
        sphere("stocking", (0, 0, 0.47), (0.18, 0.19, 0.35), cream, foot)
        sphere("soft shoe", (0, -0.18, 0.15), (0.22, 0.33, 0.16), rose, foot)
        feet.append(foot)
    sphere("cotton tail", (0, 0.43, 0.87), (0.22, 0.20, 0.22), white, rig)
    return rig, body, arms, feet


def warden():
    rig = empty("lantern warden root")
    body = empty("uniform bounce", rig)
    uniform = mat("warden deep plum", (0.27, 0.26, 0.35), 0.78)
    copper = mat("warden copper", (0.66, 0.26, 0.20), 0.58)
    sphere("long uniform", (0, 0.05, 1.11), (0.35, 0.34, 0.72), uniform, body)
    cube("uniform apron", (0, -0.31, 1.06), (0.60, 0.13, 0.82), copper, body, 0.05)
    sphere("collar", (0, -0.08, 1.68), (0.37, 0.25, 0.11), brass, body)
    sphere("mask head", (0, -0.12, 2.02), (0.36, 0.30, 0.38), uniform, body)
    cube("mask faceplate", (0, -0.39, 2.02), (0.55, 0.10, 0.48), cream, body, 0.08)
    for x in (-0.15, 0.15):
        sphere("alert eye", (x, -0.46, 2.09), (0.065, 0.035, 0.09), red, body)
    cube("tall peaked cap", (0, -0.01, 2.39), (0.77, 0.59, 0.25), uniform, body, 0.08)
    cube("brass cap plate", (0, -0.32, 2.43), (0.22, 0.06, 0.10), brass, body, 0.02)
    arms = []
    for side in (-1, 1):
        arm = empty("warden arm", body, (side * 0.36, 0.02, 1.52))
        sphere("long sleeve", (side * 0.11, -0.02, -0.27), (0.15, 0.16, 0.40), uniform, arm)
        sphere("leather glove", (side * 0.14, -0.11, -0.59), (0.13, 0.12, 0.13), copper, arm)
        arms.append(arm)
    cylinder("signal baton", (0.51, -0.35, 0.71), 0.055, 0.82, brass, body, angle=(0.18, 0, 0))
    sphere("baton light", (0.51, -0.47, 1.13), (0.10, 0.09, 0.11), lime, body)
    feet = []
    for side in (-1, 1):
        leg = empty("warden stride", rig, (side * 0.17, 0, 0))
        sphere("trouser", (0, 0, 0.55), (0.15, 0.16, 0.42), uniform, leg)
        sphere("heavy boot", (0, -0.15, 0.17), (0.20, 0.30, 0.18), ink, leg)
        feet.append(leg)
    return rig, body, arms, feet


def beetle():
    rig = empty("armored beetle")
    shell = empty("shell bounce", rig)
    sphere("beetle thorax", (0, 0, 0.45), (0.52, 0.68, 0.35), red, shell)
    sphere("shell left", (-0.20, 0.07, 0.71), (0.32, 0.50, 0.21), red, shell)
    sphere("shell right", (0.20, 0.07, 0.71), (0.32, 0.50, 0.21), rust, shell)
    cylinder("shell seam", (0, 0.07, 0.89), 0.027, 0.78, ink, shell, angle=(math.pi / 2, 0, 0))
    sphere("beetle head", (0, -0.58, 0.50), (0.38, 0.31, 0.29), ink, shell)
    for x in (-0.22, 0.22):
        sphere("hostile eye", (x, -0.81, 0.56), (0.095, 0.07, 0.08), lime, shell)
        cylinder("horn", (x * 1.4, -0.91, 0.64), 0.045, 0.40, brass, shell, angle=(0.5, 0, 0))
    legs = []
    for side in (-1, 1):
        for y in (-0.34, 0.08, 0.45):
            p = empty("joint", rig, (side * 0.43, y, 0.30))
            sphere("joint leg", (side * 0.23, 0, -0.08), (0.28, 0.10, 0.11), ink, p)
            legs.append(p)
    return rig, shell, legs


def hearth():
    rig = empty("walking hearth")
    cube("carriage", (0, 0, 0.42), (1.75, 1.20, 0.55), wood, rig, 0.14)
    for side in (-1, 1):
        for y in (-0.42, 0.42):
            cylinder("heavy wheel", (side * 1.0, y, 0.31), 0.27, 0.13, ink, rig, angle=(0, math.pi / 2, 0))
            cylinder("wheel hub", (side * 1.08, y, 0.31), 0.10, 0.14, brass, rig, angle=(0, math.pi / 2, 0))
    cube("copper furnace", (0, 0, 1.03), (1.17, 0.92, 0.85), rust, rig, 0.17)
    cube("furnace mouth", (0, -0.50, 1.04), (0.72, 0.12, 0.53), ink, rig, 0.10)
    sphere("warm flame", (0, -0.57, 1.01), (0.22, 0.05, 0.21), brass, rig)
    cube("roof", (0, 0.02, 1.57), (1.45, 1.10, 0.22), sage, rig, 0.10)
    cylinder("chimney", (0.40, 0.25, 1.89), 0.16, 0.74, slate, rig)
    sphere("chimney cap", (0.40, 0.25, 2.30), (0.23, 0.23, 0.07), brass, rig)
    for x in (-0.51, 0.51):
        sphere("lamp", (x, -0.62, 0.55), (0.11, 0.11, 0.12), lime, rig)
    return rig


def turret():
    rig = empty("seed cannon")
    cylinder("padded plinth", (0, 0, 0.26), 0.46, 0.45, wood, rig)
    cylinder("brass axle", (0, 0, 0.64), 0.20, 0.42, brass, rig)
    sphere("leaf shield", (0, 0.13, 0.96), (0.48, 0.30, 0.24), sage, rig)
    cylinder("seed barrel", (0, -0.44, 1.01), 0.18, 0.88, brass, rig, angle=(math.pi / 2, 0, 0))
    cylinder("dark muzzle", (0, -0.93, 1.01), 0.14, 0.06, ink, rig, angle=(math.pi / 2, 0, 0))
    sphere("red bulb", (0, 0.28, 1.13), (0.23, 0.27, 0.20), rust, rig)
    return rig


def anchor():
    rig = empty("threadrail grapple post")
    cylinder("stone base", (0, 0, 0.19), 0.52, 0.25, slate, rig)
    cylinder("brass foot", (0, 0, 0.33), 0.34, 0.15, brass, rig)
    cylinder("copper shaft", (0, 0, 0.92), 0.13, 1.20, rust, rig)
    cylinder("thread spool", (0, -0.06, 1.18), 0.32, 0.31, wood, rig, angle=(math.pi / 2, 0, 0))
    cylinder("spool cap", (0, -0.26, 1.18), 0.37, 0.08, brass, rig, angle=(math.pi / 2, 0, 0))
    cylinder("upper collar", (0, 0, 1.62), 0.26, 0.14, brass, rig)
    sphere("glass beacon", (0, 0, 1.91), (0.28, 0.28, 0.28), lime, rig)
    sphere("beacon core", (0, -0.15, 1.97), (0.11, 0.10, 0.13), white, rig)
    for side in (-1, 1):
        sphere("side rivet", (side * 0.25, -0.24, 0.36), (0.055, 0.04, 0.055), cream, rig)
    return rig


def pod():
    rig = empty("copper seed pods")
    cylinder("stem", (0, 0, 0.54), 0.08, 1.07, sage, rig)
    for i, (x, y, z) in enumerate(((-0.31, 0.02, 0.86), (0.34, 0.11, 1.13), (0.02, -0.12, 1.43))):
        sphere("copper pod", (x, y, z), (0.21, 0.20, 0.25), brass, rig)
        sphere("pod cap", (x, y, z + 0.20), (0.12, 0.12, 0.08), sage, rig)
    for x, y in ((-0.24, 0.19), (0.25, -0.08)):
        sphere("leaf", (x, y, 0.56), (0.35, 0.14, 0.07), sage, rig)
    return rig


def tree():
    rig = empty("honeyleaf tree")
    cylinder("thick trunk", (0, 0, 0.91), 0.20, 1.72, wood, rig, vertices=12)
    sphere("trunk foot", (0, 0, 0.22), (0.38, 0.32, 0.22), wood, rig)
    for x, y, z, sx, sy, sz in (
        (-0.50, 0.08, 1.77, 0.66, 0.57, 0.48),
        (0.45, 0.10, 1.84, 0.69, 0.55, 0.48),
        (0.00, 0.22, 2.18, 0.78, 0.64, 0.54),
        (-0.09, -0.26, 1.65, 0.74, 0.60, 0.45),
    ):
        sphere("rounded canopy", (x, y, z), (sx, sy, sz), sage if x < 0 else lime, rig, seg=16)
    for x, y, z in ((-0.55, -0.50, 1.75), (0.50, -0.45, 1.78), (0.14, -0.52, 2.21), (-0.18, -0.60, 1.62)):
        sphere("amber fruit", (x, y, z), (0.09, 0.08, 0.09), brass, rig, seg=12)
    return rig


def stone():
    rig = empty("mossy standing stone")
    cube("main stone", (0, 0.03, 0.55), (0.92, 0.68, 1.09), slate, rig, 0.17)
    cube("carved face", (0, -0.34, 0.65), (0.56, 0.05, 0.55), cream, rig, 0.04)
    sphere("moss crown", (-0.20, 0.03, 1.03), (0.54, 0.39, 0.20), sage, rig, seg=16)
    for x in (-0.18, 0.18):
        sphere("carved dot", (x, -0.39, 0.73), (0.065, 0.02, 0.065), ink, rig, seg=12)
    return rig


scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.image_settings.color_depth = "8"
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.resolution_x = 192
scene.render.resolution_y = 192
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.world.color = (0.35, 0.35, 0.35)
scene.view_settings.view_transform = "Standard"

bpy.ops.object.light_add(type="AREA", location=(-3, -4, 7))
light = bpy.context.object
light.name = "large softbox"
light.data.energy = 950
light.data.shape = "DISK"
light.data.size = 5
bpy.ops.object.light_add(type="AREA", location=(3, 2, 5))
fill = bpy.context.object
fill.data.energy = 350
fill.data.size = 6
bpy.ops.object.camera_add(location=(3.5, -5.0, 6.6))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, 0, 1.0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 3.15 if KIND in ("shopper", "warden") else 2.95 if KIND in ("hero", "hero_attack") else 2.8 if KIND == "beetle" else 4.4 if KIND == "tree" else 3.6
scene.camera = camera

if KIND in ("hero", "hero_attack", "shopper", "warden"):
    rig, body, arms, feet = {"hero": hero, "hero_attack": hero, "shopper": shopper, "warden": warden}[KIND]()
    directions = [0, math.pi / 2, math.pi, math.pi * 1.5]
    count = 5 if KIND == "hero_attack" else 6
elif KIND == "beetle":
    rig, body, legs = beetle()
    directions = [0, math.pi / 2, math.pi, math.pi * 1.5]
    count = 4
else:
    rig = {"hearth": hearth, "turret": turret, "anchor": anchor, "pod": pod, "tree": tree, "stone": stone}[KIND]()
    directions = [0]
    count = 1

for d, direction in enumerate(directions):
    rig.rotation_euler.z = direction
    for f in range(count):
        phase = f / count * math.tau
        if KIND in ("hero", "shopper", "warden"):
            body.location.z = 0.045 + abs(math.sin(phase)) * 0.07
            arms[0].rotation_euler.x = math.sin(phase) * 0.36
            arms[1].rotation_euler.x = -math.sin(phase) * 0.36
            feet[0].location.y = 0.02 + math.sin(phase) * 0.23
            feet[1].location.y = 0.02 - math.sin(phase) * 0.23
        elif KIND == "hero_attack":
            strike = f / 4.0
            body.location.z = 0.05 - math.sin(strike * math.pi) * 0.09
            body.rotation_euler.z = (strike - 0.5) * 0.22
            arms[1].rotation_euler.x = -0.8 + strike * 1.85
            arms[1].rotation_euler.y = -0.4 + strike * 0.8
            arms[0].rotation_euler.x = 0.33
            bpy.data.objects["tool haft"].rotation_euler.y = -0.50 + strike * 1.30
            bpy.data.objects["tool blade"].rotation_euler.y = -0.50 + strike * 1.30
            feet[0].location.y = -0.10
            feet[1].location.y = 0.14
        elif KIND == "beetle":
            body.location.z = abs(math.sin(phase)) * 0.045
            for i, leg in enumerate(legs):
                leg.rotation_euler.z = math.sin(phase + (i % 2) * math.pi) * 0.21
        scene.render.filepath = os.path.join(OUT, f"{KIND}_{d}_{f}.png")
        bpy.ops.render.render(write_still=True)
        if PREVIEW:
            sys.exit(0)
