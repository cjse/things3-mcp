# frozen_string_literal: true

# Puma binds to localhost only. Tailscale (or another proxy) terminates TLS.
bind "tcp://127.0.0.1:#{ENV.fetch('PORT', '9292')}"
workers 0
threads 1, 4
environment ENV.fetch('RACK_ENV', 'production')
