# Changelog

All notable development changes to LoopsubD 2 are documented here.

## [2.7.3] — Stable release

- Established the stable LoopsubD 2 development baseline.
- Retained the proven subdivision core derived from the 2.6.1 line, using SketchUp mesh triangulation.
- Retained Crease subdivision rules and Crease propagation.
- Added visual Crease marking in the Control Cage.
- Added reliable polling-based Auto Update combined with SketchUp model callbacks.
- Auto Update now detects geometry changes and Crease state changes.
- Added independent handling of multiple LoopsubD 2 instances in the same model.
- Maintained SketchUp 2020 compatibility.
- Regression-tested closed surfaces, cavities, complex meshes, Creases, Auto Update, save/reopen workflows and multiple instances.

### Important development decision

The custom polygon ear-clipping triangulation introduced during the 2.7 development line is **not part of this stable release**. Testing showed that it could introduce holes and disconnections in closed surfaces. The stable core therefore uses SketchUp's own mesh triangulation.

The later face-orientation correction developed in 2.9/2.10.1 is also not included in this release because the 2.7.3 baseline passed the orientation tests without it and the correction was not necessary to the tested stable workflow.

## [2.7.2] — Experimental

- Added visual Crease marking to the 2.7.1 baseline.
- Added polling-based Auto Update.
- Kept the stable 2.6.1-derived subdivision core.

## [2.7.1] — Experimental

- Restored the 2.6.1 subdivision core after identifying a regression associated with the custom polygon triangulation introduced in 2.7.
- Used SketchUp's mesh triangulation for stable closed-surface processing.

## [2.7] — Experimental development line

- Introduced custom polygon ear-clipping triangulation.
- The approach was subsequently abandoned for the stable release after regression testing revealed problems with some closed surfaces and cavities.

## [2.6.1]

- Added Loop subdivision rules for Crease edges.
- Crease edge points use midpoint rules.
- Crease vertices with two Crease neighbors use the appropriate crease-vertex weighting.
- Corners with three or more Crease neighbors remain fixed.
- Crease edges propagate through repeated subdivision levels.
- Fixed an Array comparison compatibility issue affecting SketchUp 2020 / Ruby 2.5.

## [2.5]

- Added Crease infrastructure.
- Added Add Crease, Remove Crease and Clear Creases commands.
- Stored Crease information on Control Cage edges.

## [2.4]

- Established the separate Control Cage / Subdivision Surface workflow.
- Added root-level Control Cage and generated Surface groups.
- Added commands to show, hide and edit the Control Cage.
- Added toolbar support.
- Improved SketchUp 2020 compatibility.
- Replaced unsupported `filter_map` usage for Ruby compatibility.

## Earlier development

LoopsubD 2 evolved from the original Loop Subdivision plugin created by Nathan B (NB70), originally developed around 2009.
