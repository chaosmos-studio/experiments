"""Render the Compassfall clockwork sentry as a transparent Blender sprite."""

import math
from pathlib import Path

import bpy
from mathutils import Vector


output = Path(__file__).resolve().parents[1] / "assets" / "sprites" / "sentry.png"
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def material(name, color, metallic, roughness):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    surface = result.node_tree.nodes.get("Principled BSDF")
    surface.inputs["Base Color"].default_value = (*color, 1)
    surface.inputs["Metallic"].default_value = metallic
    surface.inputs["Roughness"].default_value = roughness
    return result


brass = material("brushed brass", (0.75, 0.42, 0.12), 0.75, 0.28)
cream = material("porcelain inlay", (0.92, 0.87, 0.69), 0.12, 0.36)
teal = material("oxidized teal enamel", (0.05, 0.37, 0.41), 0.45, 0.3)
dark = material("dark clock glass", (0.02, 0.1, 0.14), 0.2, 0.16)
eye = material("warm eye", (1.0, 0.45, 0.15), 0.05, 0.2)


def sphere(name, point, scale, surface):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, location=point)
    result = bpy.context.object
    result.name = name
    result.scale = scale
    result.data.materials.append(surface)
    bpy.ops.object.shade_smooth()
    return result


def block(name, point, scale, surface):
    bpy.ops.mesh.primitive_cube_add(size=1, location=point)
    result = bpy.context.object
    result.name = name
    result.scale = scale
    result.data.materials.append(surface)
    bevel = result.modifiers.new("rounded edge", "BEVEL")
    bevel.width = 0.08
    bevel.segments = 3
    result.modifiers.new("weighted normals", "WEIGHTED_NORMAL")
    return result


def ring(name, radius, tube, depth, surface):
    bpy.ops.mesh.primitive_torus_add(major_segments=48, minor_segments=12, location=(0, depth, 0), major_radius=radius, minor_radius=tube)
    result = bpy.context.object
    result.name = name
    result.rotation_euler.x = math.pi / 2
    result.data.materials.append(surface)
    bpy.ops.object.shade_smooth()
    return result


sphere("enamel body", (0, 0.05, 0), (0.68, 0.27, 0.68), teal)
ring("outer brass rail", 0.82, 0.095, -0.05, brass)
ring("porcelain dial", 0.59, 0.09, -0.29, cream)
sphere("glass eye", (0, -0.32, 0), (0.38, 0.08, 0.38), dark)
sphere("lit pupil", (0, -0.41, 0), (0.15, 0.06, 0.15), eye)
for index in range(8):
    angle = math.tau * index / 8
    radius = 0.94
    point = (math.sin(angle) * radius, 0.01, math.cos(angle) * radius)
    tooth = block(f"dial tooth {index}", point, (0.2, 0.17, 0.3), brass)
    tooth.rotation_euler.y = angle
for side in (-1, 1):
    fin = block("side vane", (side * 1.05, 0.17, 0), (0.48, 0.14, 0.16), cream)
    fin.rotation_euler.y = side * 0.18

world = bpy.context.scene.world
world.use_nodes = True
world.node_tree.nodes.get("Background").inputs["Color"].default_value = (0.84, 0.94, 0.92, 1)
world.node_tree.nodes.get("Background").inputs["Strength"].default_value = 0.7


def area(name, point, energy, color, size):
    bpy.ops.object.light_add(type="AREA", location=point)
    result = bpy.context.object
    result.name = name
    result.data.energy = energy
    result.data.color = color
    result.data.shape = "DISK"
    result.data.size = size
    result.rotation_euler = (Vector((0, 0, 0)) - result.location).to_track_quat("-Z", "Y").to_euler()


area("warm key", (-3, -4, 5), 450, (1.0, 0.83, 0.59), 4)
area("blue rim", (3, 2, 4), 620, (0.46, 0.9, 1.0), 3)
bpy.ops.object.camera_add(location=(2.3, -6.7, 2.3))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 2.9
bpy.context.scene.camera = camera

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.compression = 40
scene.render.filepath = str(output)
bpy.ops.render.render(write_still=True)
print(output)
