require "openssl"
require "base64"
require "securerandom"
require "cgi"

module X
  # OAuth 1.0a HMAC-SHA1 signer for X API user-context auth.
  # Pure logic — no HTTP. Reads credentials from ENV.
  class OAuthSigner
    REQUIRED_ENV = %w[X_API_KEY X_API_SECRET X_ACCESS_TOKEN X_ACCESS_TOKEN_SECRET].freeze

    class NotConfigured < StandardError; end

    def self.creds_present?
      REQUIRED_ENV.all? { |k| ENV[k].to_s.strip != "" }
    end

    # Returns the value for an `Authorization` header.
    # `request_params` are the form-body or query params that should be
    # included in the OAuth signature base string. For multipart/form-data
    # or JSON-body POSTs, pass an empty hash.
    def self.header(method, url, request_params = {})
      raise NotConfigured, "missing one of #{REQUIRED_ENV.join(', ')}" unless creds_present?
      new.header(method, url, request_params)
    end

    def header(method, url, request_params)
      oauth = base_oauth_params
      sig_params = oauth.merge(request_params.transform_keys(&:to_s).transform_values(&:to_s))
      oauth["oauth_signature"] = sign(method, url, sig_params)
      "OAuth " + oauth.sort.map { |k, v| %{#{percent(k)}="#{percent(v)}"} }.join(", ")
    end

    private

    def base_oauth_params
      {
        "oauth_consumer_key"     => ENV.fetch("X_API_KEY"),
        "oauth_nonce"            => SecureRandom.hex(16),
        "oauth_signature_method" => "HMAC-SHA1",
        "oauth_timestamp"        => Time.now.to_i.to_s,
        "oauth_token"            => ENV.fetch("X_ACCESS_TOKEN"),
        "oauth_version"          => "1.0"
      }
    end

    def sign(method, url, params)
      param_string = params.sort.map { |k, v| "#{percent(k)}=#{percent(v)}" }.join("&")
      base = [method.upcase, percent(url), percent(param_string)].join("&")
      key  = "#{percent(ENV.fetch('X_API_SECRET'))}&#{percent(ENV.fetch('X_ACCESS_TOKEN_SECRET'))}"
      Base64.strict_encode64(OpenSSL::HMAC.digest("sha1", key, base))
    end

    # RFC 3986 percent-encoding: CGI.escape uses "+" for space and leaves "~"
    # untouched encoded; OAuth needs "%20" for space and "~" raw.
    def percent(str)
      CGI.escape(str.to_s).gsub("+", "%20").gsub("%7E", "~")
    end
  end
end
