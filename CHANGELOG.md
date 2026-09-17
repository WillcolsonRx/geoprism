# Changelog

## Interactive workbench update — unreleased

- Replaced the promotional landing layout with a light scientific workbench.
- Added orbitable 3D and 2D projections, depth shading, point selection, pinch zoom, keyboard controls, optional rotation, and group visibility controls.
- Added a sample inspector, feature heatmap, searchable/sortable table, variance chart, and CSV export.
- The browser computes centered PCA on deterministic synthetic data; optional scaling triggers a recalculation. The real-data R workflow is unchanged.
- Added a dependency-free Node.js preview server and numerical tests.
- Restyled documentation to match the workbench.

## GEOPrism presentation package — unreleased

### Added

- GEOPrism project identity, geometric icon, README banner, custom technology badges, and social preview image.
- Responsive GitHub Pages landing page, documentation page, and synthetic interactive sample-space illustration.
- Setup, methods, export-scope, contribution, publishing, and issue-reporting documentation.
- A downloadable app source bundle and a repeatable packaging script.
- Explicit `svglite` installation for SVG figure export.

### Changed

- Application title and presentation-only CSS now use GEOPrism branding.
- The supplied PCA mathematics, annotation logic, and reactive data workflow are unchanged.

### Validation

- The presentation package can be inspected independently of the R app.
- R was not available in the packaging environment; runtime installation, GEO retrieval, PCA, and figure exports still require validation in R.

### Known application behaviors to review

- Summaries and download filenames use the editable accession field. Editing it without loading can mislabel outputs from the previous dataset.
- “No labels” does not disable hover tooltips.
- Shape mapping uses ggplot2's default discrete shapes; high-cardinality metadata needs additional handling.
- PCA axis validation checks non-empty and distinct values, but does not explicitly require current component membership during reactive transitions.
- The top-feature numeric input has a UI minimum; additional server-side validation would improve robustness.
- Browser-only Plotly state is not included in static ggplot exports.
- Sample metadata downloads contain all samples in the selected ExpressionSet.

## Supplied interactive PCA patch

The original patch replaced `ifelse(..., NULL, ...)` with ordinary `if/else` logic for the optional shape legend, preventing a zero-length label value from breaking ggplot/Plotly handling. A shape legend label is only added when mapping is active. The patch also added basic PCA-axis validation.

The original patch notes state that PCA mathematics were unchanged.
