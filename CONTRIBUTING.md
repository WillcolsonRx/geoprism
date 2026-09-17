# Contributing to GEOPrism

Useful contributions include supported platform mappings, reproducible bug fixes, clearer scientific documentation, and accessibility improvements.

## Start locally

Open `GEOPrism.Rproj`, run `source("install_packages.R")`, then `shiny::runApp()`.

Keep changes focused. Explain the user-visible problem, your change, and the checks performed. For scientific changes, state whether results or preprocessing behavior change.

## Report a problem

Include the GEO accession, platform, reproduction steps, expected behavior, actual behavior, and relevant console output. Add R and package versions using `sessionInfo()`. Remove private sample metadata and credentials from attachments.

## Add an annotation platform

Update `annotation_package_for()` in `R/helpers.R`, include the dependency in `install_packages.R`, and document the platform in the README and website. Verify the annotation database's key type and identifier compatibility with an actual dataset. Check how unmapped probes and multi-symbol mappings behave.

## Change the website

The static site is in `docs/`. Open it locally or serve it with `python -m http.server 8000 --directory docs`. Check desktop and narrow-screen layouts, keyboard navigation, copy controls, local links, and source downloads. Preserve the explicit synthetic-data label on the interactive illustration.

No build process is required. Run `python tools/package_source.py` whenever application or included documentation files change.
