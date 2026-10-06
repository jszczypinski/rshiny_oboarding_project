# Biodiversity Dashboard (Poland)

Shiny dashboard of GBIF occurrence records for Poland, backed by DuckDB.

## Layout

- `app.R` — opens one read-only DuckDB connection (`lib/database.R::create_db_con`) and passes `con` into the server.
- `ui.R` / `server.R` — top-level UI (bslib `page_sidebar`) and server wiring.
- `modules/` — Shiny modules as `<name>_ui(id)` / `<name>_server(id, ...)` pairs.
- `lib/` — non-reactive code: DB queries (`database.R`), helpers (`species_helpers.R`).
- `scripts/get_data_poland.R` — optparse CLI turning a GBIF CSV into the DuckDB table `occurence_poland`.
- Packages are managed with `renv` (`renv::restore()`).

## R code style

Enforced by `air.toml` and `.lintr`:

- Line width **120**, indent **4 spaces**.
- Imports go through `box::use(...)`. Never use `library()` in app code (only `scripts/` does).
  - `pkg::fn` namespacing is not required: `object_usage_linter` is off because of `box::use`.
  - Multi-line `box::use` blocks list one import per line. air skips `use` calls (`skip = ["use"]`), so format them by hand.
- Export module/lib functions with `#' @export` and document them with roxygen `#'` comments (`@param`, `@return`).
- `renv/` and `data/` are excluded from formatting and linting.

Checks (also run by the pre-push hook):

```bash
task air     # air format .
task lintr   # Rscript -e 'lintr::lint_dir(".")'
```

## Git workflow

- Never commit on `main`. Work on a branch named `feature/<short-desc>` or `bug/<short-desc>`.
- Never `git push`. The user pushes.
- Always ask for a permission before you do a commit.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
  `<type>(<optional scope>): <description>`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Use `fix`, not `bug`.
  - The description is imperative and lowercase, with no trailing period.
  - Mark breaking changes with `!` (`feat!: ...`) or a `BREAKING CHANGE:` footer.
  - Examples: `feat(map): add species filter`, `fix(db): read OCCURENCE_DB env var`, `style: apply air formatting`.
