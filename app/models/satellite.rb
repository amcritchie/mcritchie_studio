# Pure-Ruby reader for config/satellites.yml. Not an ActiveRecord model —
# data lives in YAML, not the DB, so it ships with the repo (the navbar +
# build script need it before any DB is up).
#
# See config/satellites.yml for the schema. Add new satellites there; this
# class just reads them.
class Satellite
  CONFIG_PATH = Rails.root.join("config", "satellites.yml")
  ATTRIBUTES = %i[slug display_name emoji port heroku_app production_url role description deploy_provider status].freeze

  ATTRIBUTES.each { |attr| attr_reader attr }

  def initialize(hash)
    ATTRIBUTES.each do |attr|
      instance_variable_set("@#{attr}", hash[attr.to_s])
    end
  end

  # All satellites, in YAML order. Cached for the life of the process —
  # call .reload! after editing satellites.yml in dev to pick up changes.
  def self.all
    @all ||= YAML.load_file(CONFIG_PATH).fetch("satellites", []).map { |h| new(h) }
  end

  def self.active
    all.select { |s| s.status == "active" }
  end

  def self.find(slug)
    all.find { |s| s.slug == slug.to_s }
  end

  def self.reload!
    @all = nil
    all
  end

  def active?
    status == "active"
  end

  # URL for navbar links. In production uses production_url; in dev/test
  # uses localhost on the configured port. Appends /sso_login when logged_in
  # so the satellite auto-accepts the hub's session cookie.
  def url_for(logged_in: false)
    base = Rails.env.production? ? production_url : "http://localhost:#{port}"
    logged_in ? "#{base}/sso_login" : base
  end

  def to_param
    slug
  end
end
