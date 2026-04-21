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

  def starters
    roster_spots.where(depth: 1)
  end

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

  def person_at(position, depth: 1)
    spot = roster_spots.find_by(position: position, depth: depth)
    spot&.person
  end

  def name_slug
    "#{team_slug}-#{slate_slug}"
  end

  private

  def pick_starters(side, composition)
    spots = roster_spots.includes(person: { athlete_profile: :grades })
                        .where(side: side)
                        .to_a

    selected = []
    result = {}

    # First pass: pick all fixed groups
    composition.each do |group, config|
      next if config == :flex

      matching = spots.select { |s| config[:positions].include?(s.position) }
      sorted = sort_by_grade(matching)
      picked = sorted.first(config[:count])
      result[group] = picked
      selected.concat(picked)
    end

    # Flex DL: best remaining EDGE/DL player not already selected
    if composition.key?(:flex_dl)
      remaining = spots.select { |s| FLEX_DL_POSITIONS.include?(s.position) } - selected
      result[:flex_dl] = sort_by_grade(remaining).first(1)
    end

    # OLine guardrails: must have exactly 1 center
    if result.key?(:oline)
      result[:oline] = apply_oline_guardrails(result[:oline], spots)
    end

    # Preserve composition key order
    ordered = {}
    composition.each_key { |k| ordered[k] = result[k] if result.key?(k) }
    ordered
  end

  def sort_by_grade(spots)
    spots.sort_by do |s|
      grade = s.person&.athlete_profile&.grades&.first&.overall_grade
      [-1 * (grade || 0), s.depth]
    end
  end

  def apply_oline_guardrails(selected, all_spots)
    oline_positions = OFFENSE_COMPOSITION[:oline][:positions]
    all_oline = all_spots.select { |s| oline_positions.include?(s.position) }
    centers = selected.select { |s| s.position == "C" }

    if centers.empty?
      # Must have a center — swap 5th player for best available center
      best_center = sort_by_grade(all_oline.select { |s| s.position == "C" } - selected).first
      if best_center
        selected = selected[0..3] + [best_center]
      end
    elsif centers.size > 1
      # No duplicate centers — replace lower-graded center with next best non-center
      worst_center = sort_by_grade(centers).last
      non_centers = all_oline.select { |s| s.position != "C" } - selected
      replacement = sort_by_grade(non_centers).first
      if replacement
        idx = selected.index(worst_center)
        selected[idx] = replacement
      end
    end

    selected
  end
end
