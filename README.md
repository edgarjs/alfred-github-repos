## Install

Download from [packal](http://www.packal.org/workflow/github-repos-0) to keep it up to date.

You can also check the [releases history](https://github.com/edgarjs/alfred-github-repos/releases).

---

## Authentication

1. Call `gh-token` to generate personal access token.
2. Login by calling the `gh-login <email> <token>` action.

## Usage

1. Search your repositories by calling the `gh <term>` action.
2. Search all repositories by calling the `gha <term>` action.
3. Your repositories are cached. To force re-download cache use `gh-reset-cache` action or choose corresponding item in the `gh <term>` action.

### Other Actions

* `gh-notifications` will open your Github notifications page.

---

### Enterprise Support

If you're using an enterprise account, set your enterprise host with `gh-host <host>`.

The host value should be something like `https://example.com`

NOTE: This is an experimental feature that may not work as expected, if you find any issues please report them here: https://github.com/edgarjs/alfred-github-repos/issues
