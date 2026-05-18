# Sentry — production error monitoring.
#
# Activated only when SENTRY_DSN env var is set. In dev/test, leave SENTRY_DSN
# unset to avoid noisy issue creation.
#
# Setup steps (operator):
#   1. Create a Sentry project at https://sentry.io for the "mcritchie-studio" app
#   2. Copy the DSN from Project Settings → Client Keys (DSN)
#   3. `heroku config:set SENTRY_DSN=https://...@sentry.io/... --app mcritchie-studio`
#   4. Restart dynos: `heroku restart --app mcritchie-studio`
#
# Optional env vars:
#   SENTRY_TRACES_SAMPLE_RATE — 0.0 (default) to 1.0; performance traces sampling
#   HEROKU_SLUG_COMMIT — auto-set by Heroku, used as release identifier
if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.traces_sample_rate = (ENV["SENTRY_TRACES_SAMPLE_RATE"] || 0.0).to_f
    config.environment = Rails.env
    config.release = ENV["HEROKU_SLUG_COMMIT"] || ENV["GIT_COMMIT"]
    # Don't send Rails session cookies, IP, or PII to Sentry.
    config.send_default_pii = false
    config.send_modules = false
  end
end
