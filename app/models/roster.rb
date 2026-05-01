class Roster < ApplicationRecord
  include Sluggable

  belongs_to :team, foreign_key: :team_slug, primary_key: :slug
  belongs_to :slate, foreign_key: :slate_slug, primary_key: :slug

  has_many :roster_spots, dependent: :destroy

  validates :team_slug, presence: true, uniqueness: { scope: :slate_slug }
  validates :slate_slug, presence: true

  OFFENSE_SLOTS = %i[qb rb wr1 wr2 wr3 te flex lt lg c rg rt].freeze
  DEFENSE_SLOTS = %i[edge1 edge2 dl1 dl2 dl_flex lb1 lb2 ss fs cb1 cb2 flex].freeze

  EDGE_POSITIONS = %w[EDGE DE].freeze
  DL_POSITIONS   = %w[DT NT DL DI].freeze
  DLINE_POOL     = (EDGE_POSITIONS + DL_POSITIONS).freeze
  LB_POSITIONS   = %w[LB ILB OLB MLB].freeze
  S_POSITIONS    = %w[S FS SS].freeze
  CB_POSITIONS   = %w[CB].freeze

  SPECIAL_TEAMS_COMPOSITION = {
    k:        { positions: %w[K], count: 1 },
    p:        { positions: %w[P], count: 1 },
    ls:       { positions: %w[LS], count: 1 },
    returner: { positions: %w[WR RB FB], count: 1, sort_by: :return_grade }
  }.freeze

  PickedSpot = Struct.new(:person, :position, :depth, :side, :slot, keyword_init: true) do
    def person_slug; person&.slug; end
  end

  def offense_starters
    roster_spots.where(depth: 1, side: "offense")
  end

  def defense_starters
    roster_spots.where(depth: 1, side: "defense")
  end

  # Returns 12 ordered offensive starter slots, each mapped to a PickedSpot or nil:
  #   :qb, :rb, :wr1, :wr2, :wr3, :te, :flex, :lt, :lg, :c, :rg, :rt
  #
  # Flex is filled by the highest offense_grade among (RB depth=2, WR depth=4,
  # TE depth=2) — overrides the depth chart's RB2 because most modern offenses
  # field a 2nd TE or 4th WR more often than a true RB2.
  def offense_starting_12
    chart = team.depth_chart
    return OFFENSE_SLOTS.index_with { nil } unless chart

    spots = load_spots(chart, "offense")
    used = Set.new
    result = OFFENSE_SLOTS.index_with { nil }

    qbs = spots_at(spots, %w[QB])
    result[:qb] = take(qbs, used)

    rbs = spots_at(spots, %w[RB FB HB])
    result[:rb] = take(rbs, used)

    wrs = spots_at(spots, %w[WR])
    result[:wr1] = take(wrs, used)
    result[:wr2] = take(wrs, used)
    result[:wr3] = take(wrs, used)

    tes = spots_at(spots, %w[TE])
    result[:te] = take(tes, used)

    flex_pool = (rbs + wrs + tes).reject { |s| used.include?(s) }
    result[:flex] = pick_max(flex_pool, used) { |s| grade_value(s, :offense_grade) }

    result[:lt] = pick_ol_slot(spots, used, "LT", %w[OT T])
    used << result[:lt] if result[:lt]
    result[:lg] = pick_ol_slot(spots, used, "LG", %w[OG G])
    used << result[:lg] if result[:lg]
    result[:c]  = pick_ol_slot(spots, used, "C", [])
    used << result[:c] if result[:c]
    result[:rg] = pick_ol_slot(spots, used, "RG", %w[OG G])
    used << result[:rg] if result[:rg]
    result[:rt] = pick_ol_slot(spots, used, "RT", %w[OT T])
    used << result[:rt] if result[:rt]

    OFFENSE_SLOTS.each_with_object({}) do |slot, h|
      pick = result[slot]
      pick.slot = slot if pick
      h[slot] = pick
    end
  end

  # Returns 12 ordered defensive starter slots, each mapped to a PickedSpot or nil:
  #   :edge1, :edge2, :dl1, :dl2, :dl_flex, :lb1, :lb2, :ss, :fs, :cb1, :cb2, :flex
  #
  # Within-group sort: EDGE by pass_rush_grade, DL by defense_grade, LB by
  # run_defense_grade, CB by coverage_grade. DL Flex = highest pass_rush_grade
  # among unselected EDGE/DL. Flex (Nickel) = highest coverage_grade among
  # unselected CB/S/FS/SS — covers nickel CB or big-nickel safety.
  def defense_starting_12
    chart = team.depth_chart
    return DEFENSE_SLOTS.index_with { nil } unless chart

    spots = load_spots(chart, "defense")
    used = Set.new
    result = DEFENSE_SLOTS.index_with { nil }

    # EDGE: top 2 by depth, then resort by pass_rush_grade
    edge_pool = spots_at(spots, EDGE_POSITIONS).first(2)
                                               .sort_by { |s| -grade_value(s, :pass_rush_grade) }
    result[:edge1] = edge_pool[0]; used << edge_pool[0] if edge_pool[0]
    result[:edge2] = edge_pool[1]; used << edge_pool[1] if edge_pool[1]

    # DL: top 2 by depth, then resort by defense_grade
    dl_pool = spots_at(spots, DL_POSITIONS).first(2)
                                           .sort_by { |s| -grade_value(s, :defense_grade) }
    result[:dl1] = dl_pool[0]; used << dl_pool[0] if dl_pool[0]
    result[:dl2] = dl_pool[1]; used << dl_pool[1] if dl_pool[1]

    # DL Flex: highest pass_rush_grade among unselected EDGE/DL
    flex_dl_pool = spots.select { |s| DLINE_POOL.include?(s.position) }.reject { |s| used.include?(s) }
    result[:dl_flex] = pick_max(flex_dl_pool, used) { |s| grade_value(s, :pass_rush_grade) }

    # LB: top 2 by depth, then resort by rush_defense_grade (run-stop performance)
    lb_pool = spots_at(spots, LB_POSITIONS).first(2)
                                           .sort_by { |s| -grade_value(s, :rush_defense_grade) }
    result[:lb1] = lb_pool[0]; used << lb_pool[0] if lb_pool[0]
    result[:lb2] = lb_pool[1]; used << lb_pool[1] if lb_pool[1]

    # SS: position=SS depth=1; fall back to first generic S
    result[:ss] = spots.detect { |s| s.position == "SS" && s.depth == 1 }
    result[:ss] ||= spots_at(spots, %w[S]).reject { |s| used.include?(s) }.first
    used << result[:ss] if result[:ss]

    # FS: position=FS depth=1; fall back to next generic S
    result[:fs] = spots.detect { |s| s.position == "FS" && s.depth == 1 }
    result[:fs] ||= spots_at(spots, %w[S]).reject { |s| used.include?(s) }.first
    used << result[:fs] if result[:fs]

    # CB: top 2 by depth, then resort by coverage_grade
    cb_pool = spots_at(spots, CB_POSITIONS).first(2)
                                           .sort_by { |s| -grade_value(s, :coverage_grade) }
    result[:cb1] = cb_pool[0]; used << cb_pool[0] if cb_pool[0]
    result[:cb2] = cb_pool[1]; used << cb_pool[1] if cb_pool[1]

    # Flex (Nickel): highest coverage_grade among unselected CB/S
    nickel_pool = spots.select { |s| (CB_POSITIONS + S_POSITIONS).include?(s.position) }
                       .reject { |s| used.include?(s) }
    result[:flex] = pick_max(nickel_pool, used) { |s| grade_value(s, :coverage_grade) }

    DEFENSE_SLOTS.each_with_object({}) do |slot, h|
      pick = result[slot]
      pick.slot = slot if pick
      h[slot] = pick
    end
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

  # Backward-compat shape for the games/player_impact partials. Wraps the new
  # 12-slot offense layout in the legacy {qb:, rb:, wr:, te:, flex:, oline:}
  # array-of-picks form. New consumers should use offense_starting_12 directly.
  def offense_starters_grouped
    s = offense_starting_12
    {
      qb:    [s[:qb]].compact,
      rb:    [s[:rb]].compact,
      wr:    [s[:wr1], s[:wr2], s[:wr3]].compact,
      te:    [s[:te]].compact,
      flex:  [s[:flex]].compact,
      oline: [s[:lt], s[:lg], s[:c], s[:rg], s[:rt]].compact
    }
  end

  def defense_starters_grouped
    s = defense_starting_12
    {
      edge:    [s[:edge1], s[:edge2]].compact,
      dl:      [s[:dl1], s[:dl2]].compact,
      flex_dl: [s[:dl_flex]].compact,
      lb:      [s[:lb1], s[:lb2]].compact,
      cb:      [s[:cb1], s[:cb2]].compact,
      s:       [s[:ss], s[:fs]].compact,
      flex:    [s[:flex]].compact
    }
  end

  def name_slug
    "#{team_slug}-#{slate_slug}"
  end

  private

  def load_spots(chart, side)
    chart.depth_chart_entries
         .where(side: side)
         .includes(person: { athlete_profile: [:grades, :image_caches] })
         .to_a
         .map { |e| PickedSpot.new(person: e.person, position: e.position, depth: e.depth, side: e.side) }
  end

  def spots_at(spots, positions)
    spots.select { |s| positions.include?(s.position) }.sort_by(&:depth)
  end

  def take(pool, used)
    pick = pool.find { |s| !used.include?(s) }
    used << pick if pick
    pick
  end

  def pick_max(pool, used)
    pick = pool.max_by { |s| yield(s) }
    used << pick if pick
    pick
  end

  def pick_ol_slot(spots, used, primary_position, fallback_positions)
    pool = spots.reject { |s| used.include?(s) }
    pool.detect { |s| s.position == primary_position } ||
      pool.select { |s| fallback_positions.include?(s.position) }.min_by(&:depth)
  end

  def grade_value(spot, field)
    grade = spot.person&.athlete_profile&.grades&.first
    return -Float::INFINITY unless grade
    grade.public_send(field) || grade.overall_grade || -Float::INFINITY
  end
end
