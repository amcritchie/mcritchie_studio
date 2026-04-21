module PositionConcern
  extend ActiveSupport::Concern

  OFFENSE_POSITIONS = %w[QB RB WR TE LT LG C RG RT OT OG FB].freeze

  DEFENSE_POSITIONS = %w[EDGE DE DT NT DL LB ILB OLB MLB CB S FS SS].freeze

  SPECIAL_TEAMS_POSITIONS = %w[K P LS KR PR].freeze

  POSITION_ALIASES = {
    "HB" => "RB",
    "TB" => "RB",
    "OT" => "OT",
    "Edge" => "EDGE",
    "DI" => "DT",
    "IDL" => "DT",
    "3T" => "DT",
    "0T" => "NT",
    "1T" => "NT",
    "WLB" => "OLB",
    "SLB" => "OLB",
    "WILL" => "ILB",
    "MIKE" => "ILB",
    "SAM" => "OLB",
    "NCB" => "CB",
    "SCB" => "CB",
    "OCB" => "CB",
    "SLOT" => "CB"
  }.freeze

  # Module-level methods (callable as PositionConcern.side_for)
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

  def self.normalize_position(position)
    return position if position.nil?
    upper = position.strip.upcase
    POSITION_ALIASES[position.strip] || POSITION_ALIASES[upper] || upper
  end

  class_methods do
    def side_for(position)
      PositionConcern.side_for(position)
    end

    def normalize_position(position)
      PositionConcern.normalize_position(position)
    end
  end

  # Instance-level convenience
  def side_for(position)
    self.class.side_for(position)
  end

  def normalize_position(position)
    self.class.normalize_position(position)
  end
end
