module EncodingSanitizer
  # Sanitize a string to valid UTF-8, replacing invalid bytes and
  # stripping unpaired UTF-16 surrogates.
  # Safe to call on nil or non-String values (returns them unchanged).
  def self.sanitize_utf8(str)
    return str unless str.is_a?(String)

    str.scrub("")
       .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  end

  # Sanitize all string values in a hash (one level deep).
  def self.sanitize_hash(hash)
    return hash unless hash.is_a?(Hash)

    hash.transform_values { |v| v.is_a?(String) ? sanitize_utf8(v) : v }
  end

  # Sanitize an HTTP response body before JSON parsing.
  def self.sanitize_response_body(response)
    return response.body unless response.body.is_a?(String)

    sanitize_utf8(response.body)
  end
end
