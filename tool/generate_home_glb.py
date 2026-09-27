"""Generate the bundled GuangHeng demo home as a self-contained GLB asset."""

import json
import math
import struct
from pathlib import Path


OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "models" / "home_energy_house.glb"

binary = bytearray()
buffer_views = []
accessors = []


def append_data(data: bytes, target: int) -> int:
    while len(binary) % 4:
        binary.append(0)
    offset = len(binary)
    binary.extend(data)
    index = len(buffer_views)
    buffer_views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(data), "target": target})
    return index


def add_accessor(values, component_type, accessor_type, target, minimum=None, maximum=None):
    if component_type == 5126:
        packed = struct.pack(f"<{len(values)}f", *values)
        stride = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[accessor_type]
    elif component_type == 5123:
        packed = struct.pack(f"<{len(values)}H", *values)
        stride = 1
    else:
        raise ValueError(component_type)
    view = append_data(packed, target)
    accessor = {
        "bufferView": view,
        "componentType": component_type,
        "count": len(values) // stride,
        "type": accessor_type,
    }
    if minimum is not None:
        accessor["min"] = minimum
    if maximum is not None:
        accessor["max"] = maximum
    accessors.append(accessor)
    return len(accessors) - 1


def geometry_accessors(positions, normals, indices):
    xs = positions[0::3]
    ys = positions[1::3]
    zs = positions[2::3]
    position = add_accessor(
        positions,
        5126,
        "VEC3",
        34962,
        [min(xs), min(ys), min(zs)],
        [max(xs), max(ys), max(zs)],
    )
    normal = add_accessor(normals, 5126, "VEC3", 34962)
    index = add_accessor(indices, 5123, "SCALAR", 34963, [min(indices)], [max(indices)])
    return position, normal, index


cube_positions = []
cube_normals = []
cube_indices = []
faces = [
    ((0, 0, 1), [(-.5, -.5, .5), (.5, -.5, .5), (.5, .5, .5), (-.5, .5, .5)]),
    ((0, 0, -1), [(.5, -.5, -.5), (-.5, -.5, -.5), (-.5, .5, -.5), (.5, .5, -.5)]),
    ((1, 0, 0), [(.5, -.5, .5), (.5, -.5, -.5), (.5, .5, -.5), (.5, .5, .5)]),
    ((-1, 0, 0), [(-.5, -.5, -.5), (-.5, -.5, .5), (-.5, .5, .5), (-.5, .5, -.5)]),
    ((0, 1, 0), [(-.5, .5, .5), (.5, .5, .5), (.5, .5, -.5), (-.5, .5, -.5)]),
    ((0, -1, 0), [(-.5, -.5, -.5), (.5, -.5, -.5), (.5, -.5, .5), (-.5, -.5, .5)]),
]
for normal, vertices in faces:
    base = len(cube_positions) // 3
    for vertex in vertices:
        cube_positions.extend(vertex)
        cube_normals.extend(normal)
    cube_indices.extend([base, base + 1, base + 2, base, base + 2, base + 3])

cube_accessors = geometry_accessors(cube_positions, cube_normals, cube_indices)

# Gabled roof: ridge follows the X axis and the front of the house is +Z.
roof_positions = [
    -2.2, 3.55, -1.75, 2.2, 3.55, -1.75, 2.2, 3.55, 1.75, -2.2, 3.55, 1.75,
    -2.2, 4.65, 0, 2.2, 4.65, 0,
]
roof_faces = [
    (0, 1, 5, 0, 5, 4),
    (4, 5, 2, 4, 2, 3),
    (0, 4, 3, 0, 3, 0),
    (1, 2, 5, 1, 5, 1),
    (0, 3, 2, 0, 2, 1),
]
# Rebuild roof as independent triangles so each face has a clean normal.
rp, rn, ri = [], [], []
for face in roof_faces:
    for triangle_start in range(0, len(face), 3):
        ids = face[triangle_start:triangle_start + 3]
        if len(set(ids)) < 3:
            continue
        a = roof_positions[ids[0] * 3:ids[0] * 3 + 3]
        b = roof_positions[ids[1] * 3:ids[1] * 3 + 3]
        c = roof_positions[ids[2] * 3:ids[2] * 3 + 3]
        ab = [b[i] - a[i] for i in range(3)]
        ac = [c[i] - a[i] for i in range(3)]
        normal = [
            ab[1] * ac[2] - ab[2] * ac[1],
            ab[2] * ac[0] - ab[0] * ac[2],
            ab[0] * ac[1] - ab[1] * ac[0],
        ]
        length = math.sqrt(sum(value * value for value in normal)) or 1
        normal = [value / length for value in normal]
        base = len(rp) // 3
        for vertex in (a, b, c):
            rp.extend(vertex)
            rn.extend(normal)
        ri.extend([base, base + 1, base + 2])

roof_accessors = geometry_accessors(rp, rn, ri)


def material(name, color, metallic=0.0, roughness=0.7, emissive=None):
    result = {
        "name": name,
        "pbrMetallicRoughness": {
            "baseColorFactor": color,
            "metallicFactor": metallic,
            "roughnessFactor": roughness,
        },
    }
    if emissive:
        result["emissiveFactor"] = emissive
    return result


materials = [
    material("Concrete", [.72, .76, .78, 1]),
    material("Lawn", [.18, .48, .24, 1], roughness=.9),
    material("Warm white walls", [.91, .91, .87, 1], roughness=.82),
    material("Charcoal roof", [.055, .075, .095, 1], metallic=.15, roughness=.5),
    material("Dark trim", [.08, .10, .12, 1], metallic=.35, roughness=.35),
    material("Warm windows", [.95, .54, .18, 1], roughness=.2, emissive=[.65, .25, .06]),
    material("Solar cells", [.025, .16, .34, 1], metallic=.65, roughness=.22),
    material("Panel frame", [.55, .64, .70, 1], metallic=.8, roughness=.18),
    material("Battery cabinet", [.88, .91, .92, 1], metallic=.25, roughness=.32),
    material("Energy cyan", [.02, .82, .68, 1], metallic=.15, roughness=.2, emissive=[0, .55, .42]),
    material("Door wood", [.36, .17, .08, 1], roughness=.66),
]

meshes = []
for index, item in enumerate(materials):
    position, normal, indices = cube_accessors
    meshes.append({
        "name": f"Cube {item['name']}",
        "primitives": [{"attributes": {"POSITION": position, "NORMAL": normal}, "indices": indices, "material": index}],
    })
meshes.append({
    "name": "Gabled roof",
    "primitives": [{"attributes": {"POSITION": roof_accessors[0], "NORMAL": roof_accessors[1]}, "indices": roof_accessors[2], "material": 3}],
})

nodes = []


def add_cube(name, material_index, translation, scale, rotation=None):
    node = {"name": name, "mesh": material_index, "translation": translation, "scale": scale}
    if rotation:
        node["rotation"] = rotation
    nodes.append(node)


add_cube("Foundation", 0, [0, -.12, 0], [5.4, .24, 4.4])
add_cube("Landscaped base", 1, [0, .02, 0], [5.05, .12, 4.05])
add_cube("Ground floor", 2, [0, 1.05, 0], [4.0, 2.0, 3.0])
add_cube("Upper floor", 2, [0, 2.75, 0], [3.75, 1.55, 2.75])
nodes.append({"name": "Roof", "mesh": len(materials)})

# Front facade, windows, balcony and door.
add_cube("Front window left", 5, [-1.12, 1.15, 1.515], [1.32, 1.18, .055])
add_cube("Front window right", 5, [1.13, 1.18, 1.515], [.82, 1.16, .055])
add_cube("Upper front window left", 5, [-1.02, 2.78, 1.39], [1.18, .92, .055])
add_cube("Upper front window right", 5, [1.03, 2.78, 1.39], [1.12, .92, .055])
add_cube("Entry door", 10, [.15, 1.0, 1.55], [.62, 1.55, .09])
add_cube("Balcony", 4, [1.05, 2.22, 1.62], [1.65, .12, .48])
add_cube("Balcony rail", 7, [1.05, 2.54, 1.83], [1.65, .55, .04])
add_cube("Side window", 5, [2.015, 1.65, .15], [.055, 1.25, 1.05])

# Six photovoltaic modules mounted on the front roof plane.
angle = math.radians(32.5)
rotation_x = [math.sin(angle / 2), 0, 0, math.cos(angle / 2)]
for row, z in enumerate((.56, 1.18)):
    y = 4.65 - (1.1 / 1.75) * z + .055
    for column, x in enumerate((-1.18, 0, 1.18)):
        add_cube(f"Solar panel {row + 1}-{column + 1}", 7, [x, y - .025, z], [1.08, .045, .58], rotation_x)
        add_cube(f"Solar cells {row + 1}-{column + 1}", 6, [x, y, z], [1.0, .035, .52], rotation_x)

# Home battery and its illuminated status bar.
add_cube("Home battery", 8, [2.32, .85, 1.02], [.58, 1.52, .58])
add_cube("Battery status light", 9, [2.32, .87, 1.32], [.055, .72, .025])

# Minimal garden blocks keep the silhouette grounded without visual clutter.
for index, (x, z, sx, sz) in enumerate([
    (-2.05, 1.35, .55, .45), (-1.55, 1.7, .65, .32), (1.62, 1.72, .55, .30),
    (-2.12, -.9, .42, .65), (2.13, -.85, .38, .72),
]):
    add_cube(f"Shrub {index + 1}", 1, [x, .28, z], [sx, .48, sz])

gltf = {
    "asset": {"version": "2.0", "generator": "GuangHeng procedural model generator"},
    "scene": 0,
    "scenes": [{"nodes": list(range(len(nodes)))}],
    "nodes": nodes,
    "meshes": meshes,
    "materials": materials,
    "accessors": accessors,
    "bufferViews": buffer_views,
    "buffers": [{"byteLength": len(binary)}],
}

json_chunk = json.dumps(gltf, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
while len(json_chunk) % 4:
    json_chunk += b" "
while len(binary) % 4:
    binary.append(0)

total_length = 12 + 8 + len(json_chunk) + 8 + len(binary)
header = struct.pack("<4sII", b"glTF", 2, total_length)
json_header = struct.pack("<I4s", len(json_chunk), b"JSON")
bin_header = struct.pack("<I4s", len(binary), b"BIN\0")

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_bytes(header + json_header + json_chunk + bin_header + binary)
print(f"Generated {OUTPUT} ({OUTPUT.stat().st_size} bytes, {len(nodes)} nodes)")
