# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`voyager` is a Ruby gem (no Rails, no app) that wraps third-party social/marketing APIs (Twitter, Twitter Ads, Twitter Enterprise/Gnip, LinkedIn, Facebook, Microsoft Graph/SharePoint, Bitly, Slack webhooks, Apple Business Connect) behind one uniform client/response interface. It is consumed by CareerArc's Polaris app. It is a rename-port of the older "BlueJay" gem, so some naming and comments still reflect that lineage.

Ruby 3.3.11 (`.ruby-version`), rvm gemset `voyager` (`.ruby-gemset`, inert under rbenv). `Gemfile.lock` is gitignored.

**The gemspec deliberately declares no `required_ruby_version`.** Consumers run a range of Rubies (at least 2.7 and 3.3.11), and adding that attribute would lock out the older ones. `gem build` warns about its absence — that warning is expected, leave it. For the same reason, keep library code compatible with Ruby 2.7 syntax; the dev Ruby being 3.3.11 does not license 3.x-only features.

## Commands

```bash
bundle install
bundle exec rspec                                             # whole suite
bundle exec rspec spec/twitter_client_spec.rb                 # one file
bundle exec rspec spec/twitter_client_spec.rb -e "can tweet"  # one example
bundle exec rubocop         # rubocop ~> 0.64 (line length 225, method length 50)
```

Note: `bundle exec rake` (whose default task is `spec`) does **not** work — `rake` is not declared in the Gemfile or gemspec, so it isn't in the bundle. Use `rspec` directly, or add rake as a development dependency first.

### Specs hit live APIs

There are no mocks or VCR cassettes. Every spec constructs a real client via `SpecHelper::Config` and calls the live service — specs post real tweets, create real LinkedIn shares, etc. They require `spec/spec_config.yml` (copy from `spec_config.yml.sample`, gitignored) with real credentials per platform. Without that file `spec_helper` raises immediately, so **the suite cannot be run in CI or by an agent without credentials** — don't treat a failure to run as a code problem, and be careful about running specs that mutate live accounts.

`SpecHelper::Config` derives the YAML key from the class name: `Voyager::MicrosoftGraphClient` → `microsoft_graph`. It builds three clients per platform: `client` (valid creds), `disconnected_client` (proxied to `localhost` to force failure), `unauthorized_client` (no creds). Specs use RSpec's legacy `should` syntax.

## Architecture

Request flow: `Client#get/post/put/delete` → `perform_request` → `Voyager::Request` → `Voyager::Trace.begin` → `build_request` (Net::HTTP) → `http_start` → `Voyager::Response.new(trace_id, http_response, response_parser)` → trace logged (`debug` on success, `warn` on failure).

### Three-layer client hierarchy

1. `Voyager::Client` (`lib/voyager/client.rb`) — all HTTP plumbing: verb helpers, multipart detection/`UploadIO` conversion, `uri_with_query`, standard headers, tracing, credential filtering. Subclasses must implement `connected?`, `authorized?`, and `response_parser`.
2. Auth mixin layer — `OAuthClient` (OAuth 1.0a via the `oauth` gem; signs requests in `build_request` with `access_token.sign!`) and `OAuth2Client` (via `oauth2` ~> 1.4; injects `access_token.headers` in `build_request`, routes oauth2's Faraday traffic through a private `FilteredLogger`). Some clients bypass both: `FacebookClient` and `SlackClient` extend `Client` directly and handle their own auth (Facebook appends `access_token` + HMAC `appsecret_proof` to every request).
3. Platform clients (`lib/voyager/clients/*.rb`) — set `options[:site]`, `:path_prefix`, `:authorize_url`/`:token_url` defaults in `initialize`, then expose one method per API endpoint that just calls `get`/`post`/`put`/`delete`.

`options` is a plain hash passed to `new` and read through accessor methods; there is no options validation or struct. Paths starting with `/` are joined to `site + path_prefix`; anything else is treated as an absolute URL. `with_site` temporarily swaps the base URL (and resets the memoized consumer/token on `OAuthClient`) — used for Twitter's separate `upload.twitter.com` host.

### Responses and parsers

`Voyager::Response` normalizes everything into `successful?`, `data`, `errors`, `status`, plus rate-limit fields. It `method_missing`-delegates to `@data`, so `response["resources"]` reads straight through to the parsed hash. `Response::Pretend` is returned instead of making a call when `options[:pretend]` is set.

Each client names a parser class via `response_parser`; parsers are class-method-only and mutate the response in place (`Parser.parse_response(response, net_http_response)`). `JsonParser` is the generic base (takes an `error_key`); platform parsers layer on rate-limit header extraction and platform-specific error shapes. When adding a client, either reuse `JsonParser` or add a parser alongside it in `lib/voyager/parsers/`.

### Tracing and credential redaction (important)

`Voyager::Trace` wraps every request/response pair with a UUID, timing, and the raw HTTP wire log captured by `Voyager::Logging::HttpLogger` (installed as Net::HTTP's `set_debug_output`). Because the wire log contains full request bodies, **secrets must be declared or they will be logged**.

Declare them with the class macro `filtered_attributes :consumer_key, :secret, ...`. The list is inherited by subclasses. At request time `filtered_terms` resolves each name by calling the same-named method on the client, and `update_runtime_terms` also captures matching keys seen in query strings and hash bodies. Terms may also be regexes with named groups `(?<filtered>...)` → `[FILTERED]` or `(?<snipped>...)` → `[SNIPPED]` (Twitter uses the latter to keep base64 image blobs out of logs). **Any new client handling a token, secret, or large binary payload needs a matching `filtered_attributes` entry.**

Full request/response detail is only emitted when the response failed or `Voyager.trace!` was called. `Voyager::Logging::GelfFormatter` converts a `Trace` into a Graylog-style hash for structured logging.

### Uploads

Multipart is inferred, not requested: any Hash body whose values respond to `to_io` (or are already `UploadIO`) becomes a `Net::HTTP::Post::Multipart`, with MIME type resolved from the file path by `Voyager::MIME`. `Voyager::Util.upload_from(file_or_url)` builds an `UploadIO` from a local path or URL. Twitter's `upload_media` implements the chunked INIT/APPEND/FINALIZE/STATUS flow with 3MB base64 chunks; LinkedIn and Microsoft Graph have their own multi-step upload sequences.

## Conventions

- Section-banner comments (`# ==== Account Methods ====`) separate concerns inside client files; follow the existing grouping when adding endpoints.
- Link the vendor's API doc URL in a comment above non-obvious endpoint methods (LinkedIn and Twitter Ads do this consistently).
- New files must be `git add`ed to ship: the gemspec builds `s.files` from `git ls-files`.

## Releasing

Git-flow: work on `develop`, release/hotfix branches merge to both `master` and `develop`. A release is a bump of `Voyager::VERSION` in `lib/voyager/version.rb`, a `CHANGELOG.md` entry, and a version tag.
