# Landing page starter

A one-page landing for a product or an idea, live on [Dockhold](https://dockhold.eu)
at its own HTTPS address with no build step. Hero, three benefits, how it works,
an FAQ and a sign-up button, in plain HTML and CSS you can edit by hand or with
your AI tool. Runs on the free plan.

[![Deploy on Dockhold](https://dockhold.eu/button.svg)](https://app.dockhold.eu/new?repo=https://github.com/dockhold/landing-page-starter&name=landing-page-starter&ref=button-landing-page)

## Deploy it

1. Click **Use this template** (or fork this repo) to get your own copy.
2. Click the **Deploy on Dockhold** button above, or open the
   [Deploy link](https://app.dockhold.eu/new?repo=https://github.com/dockhold/landing-page-starter&name=landing-page-starter&ref=button-landing-page),
   connect GitHub, and pick your repo.
3. That's it. Dockhold builds the included [`Dockerfile`](Dockerfile) and serves
   the page. It goes live at `https://<your-app>.dockhold.app` with HTTPS
   handled.

Every later push to your main branch redeploys automatically.

## Deploy with your AI tool

Install the Dockhold plugin or MCP server in your AI coding tool
([setup guide](https://dockhold.eu/docs/recipes/deploy-from-your-ai-tool)), then
say "put this online" in a folder with this template. The tool signs you in
through the browser once and reports the URL when the app is live.

Or from a terminal: `npx dockhold login`, then `npx dockhold deploy`.

## How it serves

There's one moving part, the last line of the [`Dockerfile`](Dockerfile):

```dockerfile
CMD serve -l $PORT .
```

`serve` hands out the files in this folder on the port Dockhold assigns
(`$PORT`). That `$PORT` is the only rule that matters. An app must listen on the
port the platform gives it, not a hardcoded one. The `start` script in
[`package.json`](package.json) runs the same command locally.

The page is plain HTML and CSS with no JavaScript. The FAQ opens and closes
with the browser's own `<details>` element. [`.dockerignore`](.dockerignore)
keeps this README, `AGENTS.md`, the tests and the docs out of the site, so only
the page itself is public.

## Make it yours

- **Words.** Every placeholder is in [`index.html`](index.html): search for
  "Your product" and work down the page. The `<title>`, the description and
  the link preview tags at the top are what search results and chat apps show.
- **Colours.** Change `--accent` at the top of [`style.css`](style.css). The
  dark set below it follows the visitor's system setting.
- **Sign-up.** Replace `hello@example.com` with your address (it appears in the
  FAQ, the form and the "Email us instead" button). The button works as it is:
  it opens the visitor's email app, addressed to you. To collect emails in a
  form service instead, paste its endpoint into the form's `action`, as the
  comment above the form shows, and set `method="post"`. The field is named
  `email`.
- **Screenshot.** Save a picture next to `index.html` and replace the drawing
  in the "See it" section with an `<img>`, as the comment there shows.
- **Privacy and Imprint.** Point the two footer links at your own pages. A new
  page is just another `.html` file in this folder, such as `privacy.html`.
- **More pages.** Add plain `.html` files and link them with relative paths
  (`./about.html`, `./style.css`).

## Run it locally

```bash
npm install
PORT=3000 npm start
# open http://localhost:3000
```

`tests/smoke.sh` builds the image and checks the page the way it runs on
Dockhold (it needs Docker).

## Full walkthrough

[Deploy a landing page](https://dockhold.eu/docs/recipes/deploy-a-landing-page):
the step-by-step recipe.
