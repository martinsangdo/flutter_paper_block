#!/usr/bin/env python3
"""Generate solvable Paper Blocks levels (4..60).

Approach: build a clean rectilinear target silhouette (union of overlapping
rectangles — a "floor-plan" look), reject shapes with interior holes, then
partition it into fixed-orientation polyominoes. The partition is itself a valid
no-rotation solution, so solvability is structural; a backtracking exact-cover
solver double-checks each level. The emitted grid is padded with a 1-cell empty
margin on every side so the target never touches the board edge (matching the
hand-authored intro levels and avoiding rounded-corner clipping).

Emits lib/data/levels.dart. Run: python3 tool/gen_levels.py
"""
import random
from collections import deque

OUT = "/Users/sangdo/Documents/Source/Flutter/flutter_paper_block/lib/data/levels.dart"

# ---- palette (light hex); dark variant derived by scaling ----
PALETTE = [
    0xE85D75, 0x5B8AD4, 0x5DC48F, 0xF5C842, 0xA87FD4, 0xF5924E,
    0x4EC4C4, 0xE87FC4, 0x9BC44E, 0xE84E4E, 0x6C8CE0, 0xD4794E,
    0x4EB0E8, 0xD45EA8, 0x7FC46E, 0xC0A24E, 0x8E7CC4, 0xE0A05E,
]

def dark(hexv, f=0.72):
    r = (hexv >> 16) & 0xFF
    g = (hexv >> 8) & 0xFF
    b = hexv & 0xFF
    return (int(r * f) << 16) | (int(g * f) << 8) | int(b * f)

NAMES = [
    "S-Drop", "Twin Peaks", "Little Notch", "Corner Cut", "Split Bar",
    "Zig Step", "Bridge", "Hollow", "Ledge", "Slalom",
    "Anvil", "Comb", "Kite", "Terrace", "Puzzle Box",
    "Ravine", "Mosaic", "Chevron", "Lattice", "Boulder",
    "Cog", "Fjord", "Quarry", "Trellis", "Maze Wall",
    "Cathedral", "Labyrinth", "Fortress", "Citadel", "Bastion",
    "Aqueduct", "Colossus", "Pantheon", "Obelisk", "Ziggurat",
    "Catacomb", "Spire Rows", "Rampart", "Keystone", "Archipelago",
    "Monolith", "Gearworks", "Cascade II", "Foundry", "Bulwark",
    "Meridian", "Sanctum", "Great Hall", "Coliseum", "Acropolis",
    "Leviathan", "Odyssey", "Pinnacle", "Vortex", "Grand Design",
    "Magnum Opus", "Final Trial",
]

# ---------- shape carving: union of overlapping rectangles ----------
def carve_shape(rng, C, R, area):
    def rect(x0, y0, w, h):
        return {(x, y) for x in range(x0, x0 + w) for y in range(y0, y0 + h)}

    # First (base) rectangle, kept modest so the silhouette usually needs a few
    # rectangles => more interesting steps/concavities.
    w0 = rng.randint(2, max(2, C - 1))
    h0 = rng.randint(2, max(2, R - 1))
    x0 = rng.randint(0, C - w0)
    y0 = rng.randint(0, R - h0)
    cells = rect(x0, y0, w0, h0)

    guard = 0
    while len(cells) < area and guard < 60:
        guard += 1
        w = rng.randint(2, C)
        h = rng.randint(2, R)
        x = rng.randint(0, C - w)
        y = rng.randint(0, R - h)
        r = rect(x, y, w, h)
        if cells & r:  # must overlap the current region to stay connected
            merged = cells | r
            if len(merged) <= area + 4:
                cells = merged
    return cells

def bbox(region):
    cs = [c for c, r in region]
    rs = [r for c, r in region]
    return min(cs), min(rs), max(cs), max(rs)

def hole_free(region):
    """True if there are no empty cells fully enclosed by the region."""
    mc, mr, Mc, Mr = bbox(region)
    outside = set()
    dq = deque()
    for c in range(mc, Mc + 1):
        for r in (mr, Mr):
            if (c, r) not in region and (c, r) not in outside:
                outside.add((c, r)); dq.append((c, r))
    for r in range(mr, Mr + 1):
        for c in (mc, Mc):
            if (c, r) not in region and (c, r) not in outside:
                outside.add((c, r)); dq.append((c, r))
    while dq:
        c, r = dq.popleft()
        for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c + dc, r + dr)
            if mc <= n[0] <= Mc and mr <= n[1] <= Mr \
                    and n not in region and n not in outside:
                outside.add(n); dq.append(n)
    for c in range(mc, Mc + 1):
        for r in range(mr, Mr + 1):
            if (c, r) not in region and (c, r) not in outside:
                return False  # enclosed empty cell => hole
    return True

# ---------- partition into polyominoes ----------
def size_dist(rng, t):
    if t < 0.34:
        pool = [2, 3, 3, 3, 4, 4]
    elif t < 0.67:
        pool = [3, 3, 3, 4, 4, 4, 5]
    else:
        pool = [3, 4, 4, 4, 5, 5]
    return rng.choice(pool)

def partition(rng, region, t):
    uncovered = set(region)
    pieces = []
    while uncovered:
        seed = min(uncovered, key=lambda cell: sum(
            1 for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))
            if (cell[0] + a, cell[1] + b) in uncovered))
        target = min(size_dist(rng, t), len(uncovered))
        piece = {seed}
        uncovered.discard(seed)
        while len(piece) < target:
            frontier = []
            for (c, r) in piece:
                for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    n = (c + dc, r + dr)
                    if n in uncovered:
                        frontier.append(n)
            if not frontier:
                break
            nxt = rng.choice(frontier)
            piece.add(nxt)
            uncovered.discard(nxt)
        pieces.append(piece)
    changed = True
    while changed:
        changed = False
        for i, p in enumerate(pieces):
            if len(p) == 1:
                cell = next(iter(p))
                for j, q in enumerate(pieces):
                    if j == i:
                        continue
                    if any((cell[0] + a, cell[1] + b) in q
                           for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                        q |= p
                        pieces.pop(i)
                        changed = True
                        break
                if changed:
                    break
    return pieces

def normalize(piece):
    mc = min(c for c, r in piece)
    mr = min(r for c, r in piece)
    return tuple(sorted((c - mc, r - mr) for c, r in piece))

# ---------- solver: exact cover, fixed orientation (mirrors game rules) ----------
def solvable(region, piece_offsets):
    region = set(region)
    placements = []
    mc, mr, Mc, Mr = bbox(region)
    for offs in piece_offsets:
        pls = []
        for oc in range(mc, Mc + 1):
            for orr in range(mr, Mr + 1):
                cov = frozenset((oc + dc, orr + dr) for dc, dr in offs)
                if cov <= region:
                    pls.append(cov)
        if not pls:
            return False
        placements.append(pls)

    n = len(piece_offsets)
    used = [False] * n
    steps = [0]
    LIMIT = 3_000_000

    def backtrack(covered):
        if len(covered) == len(region):
            return True
        steps[0] += 1
        if steps[0] > LIMIT:
            return False
        best_opts = None
        for cell in region:
            if cell in covered:
                continue
            opts = []
            for i in range(n):
                if used[i]:
                    continue
                for pl in placements[i]:
                    if cell in pl and not (pl & covered):
                        opts.append((i, pl))
            if best_opts is None or len(opts) < len(best_opts):
                best_opts = opts
                if len(opts) == 0:
                    return False
        for (i, pl) in best_opts:
            used[i] = True
            if backtrack(covered | pl):
                return True
            used[i] = False
        return False

    return backtrack(frozenset())

# ---------- emit one generated level ----------
def gen_level(n):
    t = (n - 4) / (60 - 4)
    # Pre-padding bounding box; padded grid is (+2) in each dim and stays playable.
    C = max(5, min(9, round(5 + (9 - 5) * t)))
    R = max(4, min(7, round(4 + (7 - 4) * t)))
    frac = 0.60 + 0.20 * t
    area = min(52, max(10, round(C * R * frac)))

    for seed in range(n * 131, n * 131 + 600):
        rng = random.Random(seed)
        region = carve_shape(rng, C, R, area)
        if not (area - 3 <= len(region) <= area + 3):
            continue
        if not hole_free(region):
            continue
        mc, mr, Mc, Mr = bbox(region)
        # Skip a plain solid rectangle — we want a silhouette with some steps.
        if len(region) == (Mc - mc + 1) * (Mr - mr + 1):
            continue

        pieces = partition(rng, region, t)
        if any(len(p) == 1 for p in pieces):
            continue
        if not (3 <= len(pieces) <= 16):
            continue
        offsets = [normalize(p) for p in pieces]
        if not solvable(region, offsets):
            continue

        # Emit with a 1-cell empty margin on every side.
        cols = (Mc - mc + 1) + 2
        rows = (Mr - mr + 1) + 2
        padded = {(c - mc + 1, r - mr + 1) for c, r in region}
        return cols, rows, padded, offsets
    raise RuntimeError(f"could not generate level {n}")

def emit_grid(cols, rows, region):
    return ["".join("#" if (c, r) in region else "." for c in range(cols))
            for r in range(rows)]

def dart_piece(pid, light, cells):
    d = dark(light)
    cell_str = ", ".join(f"({dc}, {dr})" for dc, dr in cells)
    return (f"    _p('{pid}', const Color(0x{0xFF000000 | light:08X}), "
            f"const Color(0x{0xFF000000 | d:08X}), [{cell_str}]),")

def dart_level(n, name, cols, rows, region, offsets):
    grid = emit_grid(cols, rows, region)
    rows_str = "\n".join(f"      '{g}'," for g in grid)
    pcs = []
    for idx, offs in enumerate(offsets):
        pid = f"{n}{chr(ord('a') + idx)}"
        light = PALETTE[idx % len(PALETTE)]
        pcs.append(dart_piece(pid, light, offs))
    pcs_str = "\n".join(pcs)
    return f"""  Level.fromGrid(
    id: {n},
    name: '{name}',
    rows: const [
{rows_str}
    ],
    pieces: [
{pcs_str}
    ],
  ),"""

# ---------- hand-authored intro levels 1..3 (unchanged) ----------
INTRO = """  Level.fromGrid(
    id: 1,
    name: 'First Step',
    rows: const [
      '........',
      '..##....',
      '..###...',
      '....#...',
      '........',
    ],
    pieces: [
    _p('1a', const Color(0xFFE85D75), const Color(0xFFC04060), [(0, 0), (1, 0), (0, 1)]),
    _p('1b', const Color(0xFF5B8AD4), const Color(0xFF3B6AAF), [(0, 0), (1, 0), (1, 1)]),
    ],
  ),
  Level.fromGrid(
    id: 2,
    name: 'T-Drop',
    rows: const [
      '........',
      '..###...',
      '...#....',
      '...#....',
      '...##...',
      '........',
    ],
    pieces: [
    _p('2a', const Color(0xFFE85D75), const Color(0xFFC04060), [(0, 0), (1, 0), (2, 0), (1, 1)]),
    _p('2b', const Color(0xFF5B8AD4), const Color(0xFF3B6AAF), [(0, 0), (0, 1), (1, 1)]),
    ],
  ),
  Level.fromGrid(
    id: 3,
    name: 'Staircase',
    rows: const [
      '.........',
      '..##.....',
      '...###...',
      '....##...',
      '.........',
    ],
    pieces: [
    _p('3a', const Color(0xFFE85D75), const Color(0xFFC04060), [(0, 0), (1, 0)]),
    _p('3b', const Color(0xFF5B8AD4), const Color(0xFF3B6AAF), [(0, 0), (1, 0), (2, 0)]),
    _p('3c', const Color(0xFF5DC48F), const Color(0xFF3A9A6A), [(0, 0), (1, 0)]),
    ],
  ),"""

def main():
    blocks = [INTRO]
    stats = []
    samples = {}
    for n in range(4, 61):
        cols, rows, region, offsets = gen_level(n)
        name = NAMES[n - 4]
        blocks.append(dart_level(n, name, cols, rows, region, offsets))
        stats.append((n, cols, rows, len(region), len(offsets)))
        if n in (4, 20, 45, 60):
            samples[n] = emit_grid(cols, rows, region)
    header = """import 'package:flutter/material.dart';
import '../models/level.dart';
import '../models/piece.dart';

Piece _p(String id, Color c, Color d, List<(int, int)> cells) => Piece(
      id: id,
      color: c,
      darkColor: d,
      cells: cells.map((e) => PieceCell(e.$1, e.$2)).toList(),
    );

final List<Level> allLevels = [
"""
    with open(OUT, "w") as f:
        f.write(header)
        f.write("\n".join(blocks))
        f.write("\n];\n")
    print("Wrote", OUT)
    print("level  cols x rows  cells  pieces")
    for n, c, r, cells, p in stats:
        print(f"  {n:>3}   {c:>2} x {r:<2}     {cells:>3}     {p:>2}")
    for n, grid in samples.items():
        print(f"\n--- Level {n} grid (padded) ---")
        for line in grid:
            print("   " + line)

if __name__ == "__main__":
    main()
