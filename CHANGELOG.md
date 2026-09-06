# Changelog

All notable development changes to LoopsubD 2 are documented here.

## [2.10.1]

- Improved Auto Update detection for Crease changes.
- Crease state is now included in the Control Cage change signature.
- Automatic surface rebuilding responds to Crease modifications.
- Maintained compatibility with SketchUp 2020.
- Regression-tested against previous subdivision, topology, material, orientation, and Crease workflows.

## [2.10]

- Implemented reliable automatic surface updating.
- Added recurring polling combined with SketchUp model callbacks.
- Prevented rebuilding while the Control Cage is actively being edited.
- Added safeguards against recursive update loops.
- Automatic rebuilding occurs after Control Cage editing when changes are detected.

## [2.9.1]

- Fixed a compatibility issue involving the custom Point class.
- Added the missing Point subtraction operation required by face-orientation processing.
- Maintained per-face orientation correction.
- Confirmed correct front/back face orientation on generated surfaces.

## [2.9]

- Added per-face orientation correction to generated subdivision geometry.
- Generated triangle normals are compared with the expected orientation.
- Reversed faces are corrected before materials are assigned.
- Improved preservation of front/back material behavior.

## [2.8]

- Added visual marking of Crease edges in the Control Cage.
- Preserved original edge materials and rendering options when displaying Creases.
- Added temporary visual material for Crease display.
- Continued development of Auto Update behavior.

## [2.7]

- Added robust polygon triangulation using ear clipping.
- Improved handling of polygonal faces created after deletion of internal edges.
- Added triangle winding normalization based on the original face normal.
- Resolved `Points are not planar` problems encountered with certain polygonal topologies.
- Improved reliability with more complex meshes.

## [2.6.1]

- Added Loop subdivision rules for Crease edges.
- Crease edge points are generated using midpoint rules.
- Crease vertices with two Crease neighbors use the appropriate crease-vertex weighting.
- Corners with three or more Crease neighbors remain fixed.
- Crease edges propagate through repeated subdivision levels.
- Fixed Ruby compatibility issue involving Array comparison in SketchUp 2020.

## [2.5]

- Added Crease infrastructure.
- Added Add Crease command.
- Added Remove Crease command.
- Added Clear Creases command.
- Stored Crease information on Control Cage edges.

## [2.4]

- Established the stable Control Cage / Subdivision Surface workflow.
- Added separate root-level Control Cage and generated Surface groups.
- Added commands to show, hide, and edit the Control Cage.
- Added toolbar and command icons.
- Improved SketchUp 2020 compatibility.
- Replaced unsupported `filter_map` usage for Ruby compatibility.

## Earlier Development

LoopsubD 2 evolved from the original Loop Subdivision plugin created by Nathan B (NB70), originally developed around 2009.

The original project implemented Loop subdivision smoothing for SketchUp and served as the technical foundation for the subsequent development of LoopsubD 2.
