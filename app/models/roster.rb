class Roster < ApplicationRecord
  include Sluggable

  belongs_to :team, foreign_key: :team_slug, primary_key: :slug
  belongs_to :slate, foreign_key: :slate_slug, primary_key: :slug

  has_many :roster_spots, dependent: :destroy

  validates :team_slug, presence: true, uniqueness: { scope: :slate_slug }
  validates :slate_slug, presence: true

  OFFENSE_COMPOSITION = {
    qb:    { positions: %w[QB], count: 1 },
    rb:    { positions: %w[RB FB HB], count: 2 },
    wr:    { positions: %w[WR], count: 3 },
    te:    { positions: %w[TE], count: 1 },
    oline: { positions: %w[LT LG C RG RT OT OG T G], count: 5 }
  }.freeze

  DEFENSE_COMPOSITION = {
    edge:    { positions: %w[EDGE DE], count: 2 },
    dl:      { positions: %w[DT NT DL DI], count: 2 },
    flex_dl: :flex,
    lb:      { positions: %w[LB ILB OLB MLB], count: 2 },
    cb:      { positions: %w[CB], count: 3 },
    s:       { positions: %w[S FS SS], count: 2 }
  }.freeze

  FLEX_DL_POSITIONS = %w[EDGE DE DT NT DL DI].freeze

  SPECIAL_TEAMS_COMPOSITION = {
    k:        { positions: %w[K], count: 1 },
    p:        { positions: %w[P], count: 1 },
    ls:       { positions: %w[LS], count: 1 },
    returner: { positions: %w[WR RB FB], count: 1, sort_by: :return_grade }
  }.freeze

  def offense_starters
    roster_spots.where(depth: 1, side: "offense")
  end

  def defense_starters
    roster_spots.where(depth: 1, side: "defense")
  end

  def offense_starting_12
    pick_starters("offense", OFFENSE_COMPOSITION)
  end

  def defense_starting_12
    pick_starters("defense", DEFENSE_COMPOSITION)
  end

  def special_teams_starting_4
    chart = team.depth_chart
    return SPECIAL_TEAMS_COMPOSITION.transform_values { [] } unless chart

    entries = chart.depth_chart_entries
                   .includes(person: { athlete_profile: [:grades, :image_caches] })
                   .to_a
    spots = entries.map { |e| PickedSpot.new(person: e.person, position: e.position, depth: e.depth, side: e.side) }

    result = {}
    SPECIAL_TEAMS_COMPOSITION.each do |group, config|
      matching = spots.select { |s| config[:positions].include?(s.position) }
      sort_col = config[:sort_by]
      sorted   = if sort_col
                   matching.sort_by do |s|
                     grade = s.person&.athlete_profile&.grades&.first&.public_send(sort_col)
                     [-1 * (grade || 0), s.depth]
                   end
                 else
                   matching.sort_by(&:depth)
                 end
      result[group] = sorted.first(config[:count])
    end

    result
  end

  def name_slug
    "#{team_slug}-#{slate_slug}"
  end

  private

  # Reads the team's DepthChart and emits a RosterSpot-shaped struct so views
  # don't need to change. Depth is set manually via the depth-chart UI; locked
  # entries persist across re-seeds.
  PickedSpot = Struct.new(:person, :position, :depth, :side, keyword_init: true) do
    def person_slug; person&.slug; end
  end

  def pick_starters(side, composition)
    chart = team.depth_chart
    return composition.transform_values { [] } unless chart

    spots = chart.depth_chart_entries
                 .where(side: side)
                 .includes(person: { athlete_profile: [:grades, :image_caches] })
                 .to_a
                 .map { |e| PickedSpot.new(person: e.person, position: e.position, depth: e.depth, side: e.side) }

    selected = []
    result = {}

    composition.each do |group, config|
      next if config == :flex

      matching = spots.select { |s| config[:positions].include?(s.position) }
      picked   = matching.sort_by(&:depth).first(config[:count])
      result[group] = picked
      selected.concat(picked)
    end

    if composition.key?(:flex_dl)
      remaining = spots.select { |s| FLEX_DL_POSITIONS.include?(s.position) } - selected
      result[:flex_dl] = remaining.sort_by(&:depth).first(1)
    end

    if result.key?(:oline)
      result[:oline] = apply_oline_guardrails(result[:oline], spots)
    end

    composition.each_key.each_with_object({}) { |k, acc| acc[k] = result[k] if result.key?(k) }
  end

  def apply_oline_guardrails(selected, all_spots)
    oline_positions = OFFENSE_COMPOSITION[:oline][:positions]
    all_oline = all_spots.select { |s| oline_positions.include?(s.position) }
    centers = selected.select { |s| s.position == "C" }

    if centers.empty?
      best_center = (all_oline.select { |s| s.position == "C" } - selected).sort_by(&:depth).first
      selected = selected[0..3] + [best_center] if best_center
    elsif centers.size > 1
      worst_center = centers.max_by(&:depth)
      non_centers = (all_oline.reject { |s| s.position == "C" } - selected).sort_by(&:depth)
      replacement = non_centers.first
      if replacement
        idx = selected.index(worst_center)
        selected[idx] = replacement
      end
    end

    selected
  end
end
