# LoopsubD 2

LoopsubD 2 is a SketchUp plugin for Loop subdivision modeling, evolved from the original Loop Subdivision plugin by Nathan B (NB70).

## Current release

**Version 2.7.3**

This release is the stable, tested development line of LoopsubD 2. It focuses on a non-destructive Control Cage workflow, Crease support, and automatic updates while maintaining compatibility with SketchUp 2020.

## Features

- Non-destructive **Control Cage / Subdivision Surface** workflow.
- Subdivision levels from **0 to 4**.
- Manual surface update.
- **Auto Update** after Control Cage editing.
- **Crease** edges with Loop subdivision crease rules.
- Visual marking of Crease edges while the Control Cage is visible.
- Add, Remove and Clear Creases.
- Independent multiple subdivision objects in the same SketchUp model.
- Preservation of source face materials where applicable.
- Control Cage and generated surface stored as separate root-level groups.
- SketchUp 2020-compatible Ruby implementation.

## Installation

1. Open SketchUp's **Extension Manager**.
2. Choose **Install Extension**.
3. Select the `LoopsubD2_2.7.3.rbz` package.
4. Enable the Loop Subdivision toolbar if it is not already visible.

The plugin creates a **Loop Subdivision** toolbar and corresponding commands under SketchUp's Tools menu.

## Basic workflow

1. Select the geometry to be used as the control mesh.
2. Choose **Create Subdivision**.
3. The original geometry becomes the hidden **Control Cage** and a separate **Subdivision Surface** is generated.
4. Use **Edit Control Cage** to modify the control mesh.
5. With Auto Update enabled, the subdivision surface is rebuilt automatically after leaving Cage edit mode.
6. Use **Add Crease** on selected edges when sharper control is required.

## Topology

Loop subdivision operates on triangular topology. The current stable core intentionally relies on SketchUp's own mesh triangulation rather than the experimental custom polygon ear-clipping implementation developed in an earlier version. This decision was made after regression testing of closed surfaces and cavities.

As with subdivision modeling in general, topology strongly influences the result. Non-manifold or unusual geometry may produce unexpected results.

## Testing status

The 2.7.3 baseline has been tested with:

- simple and complex closed surfaces;
- surfaces containing cavities;
- Crease creation, removal and clearing;
- Auto Update for geometry and Crease changes;
- geometry and Crease changes in the same edit session;
- saving and reopening SketchUp models;
- multiple independent LoopsubD 2 objects in the same model;
- continued editing and updating of those independent objects;
- subdivision levels up to level 4.

## Compatibility

The project is intended for **SketchUp 2020 and later**.

## Attribution

LoopsubD 2 is based on the original Loop Subdivision plugin created by **Nathan B (NB70)**. LoopsubD 2 development is by **Marcos Netto**, with development assistance from **OpenAI ChatGPT**.

See [CREDITS.md](CREDITS.md) for the project history and licensing-history note.

## License history

The original 2009 source examined during development does not contain a formal license declaration. A later version committed to the NB70 GitHub repository in 2012 contains the comment `# Apache 2.0 license`. The available repository history does not establish when or under what circumstances that notice was introduced. This repository therefore documents the historical information explicitly rather than making a stronger licensing claim than the available source supports.

## Documentation

- [CHANGELOG.md](CHANGELOG.md)
- [CREDITS.md](CREDITS.md)
