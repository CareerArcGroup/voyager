# Change Log

## [0.4.15]

- Upgrade `oauth` from `~> 0` to `~> 1.1, >= 1.1.8`.

## [0.4.13]

- Upgrade `oauth2` from `~> 1.4` to `>= 2.0.22, < 3` for [GHSA-pp92-crg2-gfv9][GHSA-pp92-crg2-gfv9] / CVE-2026-54603.
- `Voyager::OAuth2Client` pins `auth_scheme: :request_body`; oauth2 v2 changed the default to `:basic_auth`.
- Filter the credentials of an `Authorization: Basic` header out of the trace log.
- Add `Voyager::OAuth2Client#refresh_token`, and add it to `filtered_attributes`.
- `Voyager::OAuth2Client#access_token` returns `nil` when there is neither a token nor a refresh token, rather than raising the `OAuth2::Error` oauth2 v2 raises.
- `Voyager::AppleClient#ensure_token` guards its expiry check with `access_token&.expired?`.

[GHSA-pp92-crg2-gfv9]: https://github.com/ruby-oauth/oauth2/security/advisories/GHSA-pp92-crg2-gfv9

## [BlueJay 4.5.8]

> Entries at and below this point predate the voyager rename and use BlueJay's version numbering.

- Upgrade oauth2 library to 1.4.2 to support logging using `http_logger` with `OAuth2::Client` & `OAuth2::AccessToken`.
