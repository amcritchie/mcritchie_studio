module PositionConcern
  extend ActiveSupport::Concern

  OFFENSE_POSITIONS = %w[QB RB WR TE LT LG C RG RT OT OG FB].freeze

  DEFENSE_POSITIONS = %w[EDGE DE DT NT DL LB ILB OLB MLB CB S FS SS].freeze

  SPECIAL_TEAMS_POSITIONS = %w[K P LS KR PR].freeze

  # Per-source vocabulary mappings. Each external service uses its own position
  # labels (ESPN says "LDE", PFF says "ED", nflverse says "DE"). Keep one map
  # per source so the conversion stays explicit and auditable. Pass `source:`
  # to normalize_position to dispatch; falls back to GENERAL_MAP when omitted.
  GENERAL_MAP = {
    "HB" => "RB", "TB" => "RB",
    "Edge" => "EDGE", "ED" => "EDGE",
    "DI" => "DT", "IDL" => "DT", "3T" => "DT",
    "0T" => "NT", "1T" => "NT",
    "G" => "OG", "T" => "OT", "OL" => "OT",
    "DB" => "S",
    "WLB" => "OLB", "SLB" => "OLB",
    "WILL" => "ILB", "MIKE" => "ILB", "SAM" => "OLB",
    "NCB" => "CB", "SCB" => "CB", "OCB" => "CB", "SLOT" => "CB"
  }.freeze

  # ESPN's per-team depth chart pages use formation-specific labels. Collapse
  # WLB/SLB/LILB/RILB → LB, FS/SS → S, LDE/RDE → EDGE so they match the
  # generic positions our contracts use.
  ESPN_MAP = {
    "LDE" => "EDGE", "RDE" => "EDGE", "DE" => "EDGE",
    "OLB" => "LB", "ILB" => "LB", "MLB" => "LB",
    "WLB" => "LB", "SLB" => "LB", "LILB" => "LB", "RILB" => "LB",
    "MIKE" => "LB", "WILL" => "LB", "SAM" => "LB",
    "LCB" => "CB", "RCB" => "CB", "NB" => "CB", "NCB" => "CB", "SCB" => "CB",
    "FS"  => "S",  "SS"  => "S",
    "PK"  => "K"
  }.freeze

  # PFF CSV vocabulary — uses HB for halfback, ED for edge, T/G for tackle/guard.
  PFF_MAP = {
    "HB" => "RB",
    "T"  => "OT", "G" => "OG",
    "ED" => "EDGE",
    "DI" => "DT"
  }.freeze

  # nflverse roster CSV — closer to standard, but uses T/G and breaks LB into ILB/OLB/MLB.
  NFLVERSE_MAP = {
    "T"   => "OT", "G" => "OG",
    "DE"  => "EDGE",
    "ILB" => "LB", "OLB" => "LB", "MLB" => "LB",
    "FS"  => "S",  "SS" => "S"
  }.freeze

  # Spotrac contract data — mirrors nflverse vocabulary in practice.
  SPOTRAC_MAP = {
    "T"   => "OT", "G" => "OG",
    "DE"  => "EDGE",
    "ILB" => "LB", "OLB" => "LB", "MLB" => "LB",
    "FS"  => "S",  "SS" => "S"
  }.freeze

  SOURCE_MAPS = {
    espn:     ESPN_MAP,
    pff:      PFF_MAP,
    nflverse: NFLVERSE_MAP,
    spotrac:  SPOTRAC_MAP
  }.freeze

  def self.side_for(position)
    normalized = normalize_position(position)
    if OFFENSE_POSITIONS.include?(normalized)
      "offense"
    elsif DEFENSE_POSITIONS.include?(normalized)
      "defense"
    elsif SPECIAL_TEAMS_POSITIONS.include?(normalized)
      "special_teams"
    else
      "offense"
    end
  end

  def self.normalize_position(position, source: nil)
    return position if position.nil?
    raw = position.strip
    upper = raw.upcase
    if source && (map = SOURCE_MAPS[source])
      mapped = map[raw] || map[upper]
      return mapped if mapped
    end
    GENERAL_MAP[raw] || GENERAL_MAP[upper] || upper
  end

  class_methods do
    def side_for(position)
      PositionConcern.side_for(position)
    end

    def normalize_position(position, source: nil)
      PositionConcern.normalize_position(position, source: source)
    end
  end

  def side_for(position)
    self.class.side_for(position)
  end

  def normalize_position(position, source: nil)
    self.class.normalize_position(position, source: source)
  end
end
