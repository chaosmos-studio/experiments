"""Render the original Compassfall pilot as transparent sprite frames with Blender 5.2."""

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "sprites"
OUTPUT.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def material(name, color, metallic=0.0, roughness=0.55):
    value = bpy.data.materials.new(name)
    value.diffuse_color = (*color, 1)
    value.use_nodes = True
    bsdf = value.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return value


cream = material("porcelain suit", (0.92, 0.88, 0.72))
teal = material("enamel teal", (0.13, 0.53, 0.55), 0.27)
dark = material("graphite joints", (0.045, 0.085, 0.12), 0.34)
gold = material("warm brass", (0.99, 0.61, 0.23), 0.55)
glass = material("visor glass", (0.035, 0.18, 0.26), 0.25, 0.16)
light = material("eye lights", (0.8, 1.0, 0.87))


def uv_sphere(name, location, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return obj


def cube(name, location, scale, mat, bevel=0.12):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("soft edges", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        obj.modifiers.new("weighted normals", "WEIGHTED_NORMAL")
    return obj


torso = uv_sphere("torso", (0, 0, 1.2), (0.52, 0.35, 0.56), cream)
backpack = cube("battery backpack", (0, 0.29, 1.23), (0.65, 0.25, 0.64), teal)
uv_sphere("collar", (0, -0.03, 1.63), (0.45, 0.37, 0.16), gold)
uv_sphere("helmet", (0, -0.01, 1.98), (0.6, 0.5, 0.52), cream)
uv_sphere("visor rim", (0, -0.39, 2.0), (0.49, 0.14, 0.34), gold)
uv_sphere("visor", (0, -0.49, 2.01), (0.44, 0.1, 0.29), glass)
for x in (-0.17, 0.17):
    uv_sphere("eye", (x, -0.58, 2.02), (0.065, 0.025, 0.09), light)
uv_sphere("helmet badge", (0, -0.48, 2.37), (0.11, 0.04, 0.07), gold)
cube("chest badge", (0, -0.35, 1.34), (0.3, 0.04, 0.17), teal, 0.04)

arms = []
legs = []
for side in (-1, 1):
    arm = uv_sphere("arm", (side * 0.59, -0.02, 1.25), (0.18, 0.2, 0.41), teal)
    cuff = uv_sphere("glove", (side * 0.64, -0.05, 0.84), (0.19, 0.2, 0.19), cream)
    arms.append((arm, cuff, side))
    leg = uv_sphere("leg", (side * 0.25, 0.0, 0.66), (0.22, 0.25, 0.42), teal)
    boot = cube("boot", (side * 0.25, -0.12, 0.26), (0.32, 0.47, 0.28), dark)
    legs.append((leg, boot, side))

world = bpy.context.scene.world
world.color = (0.8, 0.82, 0.8)
world.use_nodes = True
world.node_tree.nodes.get("Background").inputs["Color"].default_value = (0.82, 0.91, 0.91, 1)
world.node_tree.nodes.get("Background").inputs["Strength"].default_value = 0.8

def area(name, location, energy, color, size):
    bpy.ops.object.light_add(type="AREA", location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.energy = energy
    obj.data.color = color
    obj.data.shape = "DISK"
    obj.data.size = size
    obj.rotation_euler = (Vector((0, 0, 1.3)) - obj.location).to_track_quat("-Z", "Y").to_euler()


area("large warm key", (-3, -4, 6), 550, (1.0, 0.84, 0.6), 5)
area("cool rim", (3, 2, 4), 750, (0.45, 0.9, 1.0), 3)
bpy.ops.object.camera_add(location=(4.3, -8, 3.1))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, 0, 1.37)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 3.35
bpy.context.scene.camera = camera

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.color_depth = "8"
scene.render.image_settings.compression = 40


def pose(step, gait, airborne=False):
    for arm, cuff, side in arms:
        swing = math.sin(step * math.tau) * gait * side
        arm.location.z = 1.25 + swing * 0.18
        arm.rotation_euler.y = swing * 0.5
        cuff.location.z = 0.84 + swing * 0.27
        cuff.location.y = -0.05 - abs(swing) * 0.08
    for leg, boot, side in legs:
        swing = math.sin(step * math.tau) * gait * side
        leg.rotation_euler.y = -swing * 0.55
        leg.location.z = 0.66 - abs(swing) * 0.07
        boot.location.z = 0.26 + max(0, swing) * 0.18
        boot.location.y = -0.12 + swing * 0.12
    torso.location.z = 1.2 + (0.09 if airborne else 0.035 * math.sin(step * math.tau * 2))


for name, count, gait, airborne in (("idle", 6, 0.08, False), ("run", 8, 0.72, False), ("float", 4, 0.3, True)):
    for frame in range(count):
        pose(frame / count, gait, airborne)
        scene.render.filepath = str(OUTPUT / f"pilot_{name}_{frame:02d}.png")
        bpy.ops.render.render(write_still=True)
        print(scene.render.filepath)
