"""Rebuild the website's app-only download. Run from any working directory."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
output = root / "docs" / "downloads" / "GEOPrism-source.zip"
output.parent.mkdir(parents=True, exist_ok=True)
files = [root / name for name in (
    "app.R", "install_packages.R", "GEOPrism.Rproj"
)]
if (root / "LICENSE").is_file():
    files.append(root / "LICENSE")
files += sorted((root / "R").rglob("*.R"))
files += sorted((root / "www").rglob("*"))
readme = """# GEOPrism

A clearer view of gene expression.

## Run locally

Open GEOPrism.Rproj in RStudio, or set your R working directory to this folder.
In the R console, run:

```r
source("install_packages.R")
shiny::runApp()
```

Internet access is required for package installation and GEO downloads.
Built-in gene annotation supports GPL570 and GPL6244. Other platforms do not
have built-in gene mapping/PCA. No normalization or log transformation is added.
Licensed under Apache License 2.0; see LICENSE.
This app-only download omits the full repository development assets.
See the included guide for methods, export scope, and troubleshooting.
R runtime verification is still required for this presentation release.
"""
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for path in files:
        if path.is_file():
            archive.write(path, "GEOPrism/" + str(path.relative_to(root)))
    archive.writestr("GEOPrism/README.md", readme)
    # Include an offline copy of the documentation with its dependencies.
    for relative in ("guide.html", "index.html", "assets/site.css", "assets/site.js",
                     "assets/config.js", "assets/explorer-core.js", "assets/guide.css", "assets/favicon.svg", "assets/social-preview.png"):
        path = root / "docs" / relative
        if path.is_file():
            content = path.read_bytes()
            if path.suffix == ".html":
                # The nested app download has no recursive archive link.
                content = content.replace(b'href="downloads/GEOPrism-source.zip" download', b'href="../README.md"')
                content = content.replace(b'Download source', b'App setup').replace(b'Source \xe2\x86\x93', b'App setup')
                content = content.replace(b'Download the app source', b'Read the app setup notes')
            archive.writestr("GEOPrism/guide/" + relative, content)
print(f"Created {output.relative_to(root)} ({output.stat().st_size:,} bytes)")
