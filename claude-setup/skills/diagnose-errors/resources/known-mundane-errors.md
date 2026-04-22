# Known Mundane Error Patterns

This file tracks error patterns that have been identified as mundane/expected. Update this list as new patterns are confirmed by the user.

## Routing Errors (ActionController::RoutingError)

- `/favicon.ico` — browsers requesting missing favicon
- `/robots.txt` — crawlers requesting missing robots file
- `/.env`, `/wp-admin`, `/wp-login.php` — automated vulnerability scanners
- `/xmlrpc.php`, `/admin`, `/administrator` — WordPress/CMS scanners
- `/.git/config`, `/.aws/credentials` — credential scanners

## Bot/Crawler Errors

- Errors from user agents containing: `bot`, `spider`, `crawler`, `slurp`, `Googlebot`, `Bingbot`, `Baiduspider`, `facebookexternalhit`, `Twitterbot`
- These often trigger JavaScript errors or attempt unsupported routes

## Client-Side / Browser Errors

- `TypeError: Cannot read properties of undefined` from older browsers with no polyfill
- `ResizeObserver loop limit exceeded` — benign browser warning

## External Service Timeouts

- `Net::ReadTimeout` to external APIs during known maintenance windows
- `Faraday::TimeoutError` for non-critical external calls (analytics, tracking)

## Host Authorization Blocks

- `Blocked hosts: wedding-rsvp.fly.dev` — direct Fly.io hostname access blocked by `ActionDispatch::HostAuthorization`. Expected since the app only allows `theysaidyes.rsvp`. Caused by health checks or direct access attempts.

## CSRF Token Failures

- `ActionController::InvalidAuthenticityToken` — expired sessions, bots submitting stale forms, or users with cached pages. Low frequency is expected; only investigate if it spikes.

## Health Check Noise

- Errors on `/up` or `/health` endpoints from infrastructure probes
