# Interactive workbench validation

## Completed

- Eight Node tests pass: deterministic data, PCA eigenpairs and orthogonality,
  centered/scaled behavior, rank-one data, invalid inputs, 3D/2D projection,
  point picking, and local HTTP delivery (including source download).
- Independently compared both PCA modes with NumPy SVD. Maximum eigenvalue
  differences were below 6e-14 on the generated 72 × 36 matrix.
- JavaScript syntax checks for browser scripts and Node tools.
- Local HTML navigation/asset checks and source archive integrity checks.

## Not completed

- Browser rendering and end-to-end gesture/interaction testing. The available
  browser previously blocked access to local preview files; that restriction
  has not been bypassed.
- R application installation, GEO retrieval, PCA results, and R exports.
  No R runtime is available in this environment.

The website computes PCA from synthetic values only. Its 3D renderer uses
perspective projection on HTML Canvas with orbit, depth ordering and point
picking. Node.js serves the static preview; no production server is required.
The R app's scientific workflow is unchanged.
