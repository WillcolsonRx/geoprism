# Publishing GEOPrism

Repository: https://github.com/WillcolsonRx/geoprism
Website: https://willcolsonrx.github.io/geoprism/

## Repository layout

- `app.R`, `R/`, `www/`, `install_packages.R`, and `GEOPrism.Rproj`: R Shiny app.
- `docs/`: public static landing page, browser demo, guide, and app download.
- `tests/`, `tools/`, `package.json`: development and verification tools.
- `.github/`: contributor issue templates and maintainer notes.
- `GEOPrism-preview.html`: generated local preview, excluded from Git.

## Update the website

GitHub Pages publishes `main` from `/docs`. Run `npm test` before pushing.
Rebuild the downloadable app after app, guide, or license changes:

```sh
npm run package:app
```

Commit the refreshed `docs/downloads/GEOPrism-source.zip` with the sources.
For a self-contained local preview, run `npm run preview:build`.

## R app hosting

GitHub Pages serves static files; the R Shiny app needs an R-capable host.
After deployment, set `appUrl` in `docs/assets/config.js` to its HTTPS URL.
Verify GEO retrieval, PCA, and exports in R before announcing a tested release.
See [validation notes](VALIDATION.md) and [known limitations](../CHANGELOG.md).

## License

The project uses [Apache License 2.0](../LICENSE). Include LICENSE in app downloads.
Dependencies and source datasets retain their own licenses and terms.
