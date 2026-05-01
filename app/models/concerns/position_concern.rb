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
  # the L/R/W/M/S formation prefixes (LDE/RDE → EDGE, WLB/SLB/LILB → LB) to
  # match the generic positions our contracts use. FS and SS pass through as
  # canonical so the depth chart can carry the safety subtype.
  ESPN_MAP = {
    "LDE" => "EDGE", "RDE" => "EDGE", "DE" => "EDGE",
    "OLB" => "LB", "ILB" => "LB", "MLB" => "LB",
    "WLB" => "LB", "SLB" => "LB", "LILB" => "LB", "RILB" => "LB",
    "MIKE" => "LB", "WILL" => "LB", "SAM" => "LB",
    "LCB" => "CB", "RCB" => "CB", "NB" => "CB", "NCB" => "CB", "SCB" => "CB",
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

  # ESPN formation_slot → display group (offense/defense). Each formation
  # slot lists the display groups it CAN feed; athlete.position picks which
  # group it actually fills. This disambiguates ambiguous slots WITHOUT
  # scheme detection: LDE/RDE feed :edge in 4-3 (athlete=EDGE) and :dl in
  # 3-4 (athlete=DT); WLB/SLB feed :edge in 3-4 (athlete=EDGE) and :lb in
  # 4-3 (athlete=LB). Used by Roster#defense_starting_12.
  FORMATION_GROUPS = {
    "WLB"  => [:edge, :lb],
    "SLB"  => [:edge, :lb],
    "LILB" => [:lb],
    "RILB" => [:lb],
    "MLB"  => [:lb],
    "LB"   => [:lb],
    "ILB"  => [:lb],
    "OLB"  => [:edge, :lb],
    "LDE"  => [:edge, :dl],
    "RDE"  => [:edge, :dl],
    "DE"   => [:edge, :dl],
    "LDT"  => [:dl],
    "RDT"  => [:dl],
    "NT"   => [:dl],
    "DT"   => [:dl],
    "DL"   => [:dl],
    "LCB"  => [:cb],
    "RCB"  => [:cb],
    "CB"   => [:cb],
    "SS"   => [:ss],
    "FS"   => [:fs],
    "S"    => [:ss, :fs],
    "NB"   => [:nickel],
    "NCB"  => [:nickel],
    "SCB"  => [:nickel]
  }.freeze

  # athlete.position values that "claim" each display group. When a
  # formation slot has multiple eligible groups, the picker uses these to
  # match the athlete to one of them.
  GROUP_ATHLETE_POSITIONS = {
    edge:   %w[EDGE DE],
    dl:     %w[DT NT DL DI],
    lb:     %w[LB ILB OLB MLB],
    cb:     %w[CB],
    ss:     %w[SS S],
    fs:     %w[FS S],
    nickel: %w[CB S SS FS]
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
