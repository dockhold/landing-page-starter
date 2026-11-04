# AGENTS.md

A one-page landing in plain HTML and CSS, served by `serve` on the port Dockhold assigns; no build step, no JavaScript. Deploy target: Dockhold (https://dockhold.eu).

## Deploy from this folder (local code, no GitHub repo needed)

1. `npx dockhold login` once. It opens the browser to sign in; the token is stored in the user's config directory, never in this folder.
2. `npx dockhold deploy --name landing-page-starter` from this folder.
3. Report the URL the command prints. Never claim a URL is live before the command prints it. Run the same command again to ship a new version; it updates the same app because the CLI recorded the app id in `.dockhold/app.json` (no secret in it, and the CLI adds it to `.gitignore`).

The build uses the Dockerfile at the root on every account. Without it, Dockhold recognises a static site and serves it on every account.

## Push-to-deploy (from a GitHub repo)

- The Deploy button link in README.md opens the Dockhold dashboard with the repo and name pre-filled; the user signs in, confirms, and the app builds: https://app.dockhold.eu/new?repo=https://github.com/dockhold/landing-page-starter&name=landing-page-starter&ref=button-landing-page
- Or the `deploy_app` MCP tool with `repo_url` set to this repository's GitHub URL (the user's copy if they forked or used the template) and `name`. Poll `get_app_status` for the URL.
- Pushes redeploy automatically only when the repo was connected through GitHub in the dashboard (the repo picker, or a private repo). A repo deployed by URL alone deploys by hand until "Auto-deploy on push" is set up under the app's Settings.

## Editing the page

- All words are in `index.html`, all styling in `style.css`. Fill the placeholders ("Your product", "Your company", `hello@example.com`) from what the user tells you; do not invent customers, quotes, logos or numbers.
- Keep the sections in order: top bar, hero, three benefits, how it works, "See it", FAQ, sign-up, footer.
- Keep it free of JavaScript. The FAQ uses `<details>` and `<summary>`.
- Sign-up: replace every `hello@example.com`. For a form service, set the form's `action` to the endpoint the user gives you and `method="post"`; keep the `mailto:` button as the fallback.
- Keep it mobile friendly: one column under 720 px, 16 px base font, tap targets at least 44 px tall, no horizontal scroll, visible focus outlines. Colours stay as tokens on `:root`, with a dark set under `prefers-color-scheme: dark`.
- Update the `<title>`, the description and the `og:` and `twitter:` tags with the real product name and line. An `og:image` needs an absolute URL.
- Run `tests/smoke.sh` after a change to the section structure, and update its checks if you add or remove a section on purpose.

## Configuration

- `PORT` is set by Dockhold. Do not set it, and never hardcode a port.
- No other variable is required.
- Secrets (tokens, API keys, passwords) never go in a file in this repo: not in `.env`, not in `dockhold.json`, not in code, not in a commit. Create them in the Secrets section of the Dockhold dashboard and attach them on the app's Variables page.
- Plain (non-secret) variables: the app's Variables page in the dashboard, or `--env KEY=VALUE` on `npx dockhold deploy` (repeatable). A local `.env` file is never uploaded.
- Never put a secret in this site: everything served to the browser is public.

## When a build or start fails

Run `npx dockhold logs --type build` (or `--type app` for runtime logs), read the error, fix the app, deploy again. Do not invent CLI flags. The CLI has exactly: `login [--token]`, `deploy [--name <name>] [--env KEY=VALUE ...] [--db]`, `logs [--app <id>] [--tail <n>] [--type app|build|db]`, `list`, `open [--app <id>]`.
