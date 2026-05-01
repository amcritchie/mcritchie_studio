# Consolidates suffix-stripped duplicate Person records into the canonical
# (with-suffix) Person. The Spotrac importer used to strip "Jr.", "Sr.",
# "II", "III" etc. from last names while PFF / nflverse kept the suffix,
# producing two Person+Athlete records for the same player. The canonical
# one accumulated cross-ref IDs (gsis_id, pff_id, espn_id, otc_id, pfr_id);
# the duplicate accumulated contracts, depth chart entries, and headshots.
#
# This utility moves the duplicate's data onto the canonical record and
# deletes the duplicate. Conflicts (e.g. both have a Contract for the same
# team) drop the duplicate's row in favor of the canonical one.
#
# Defaults to dry-run. Pass dry_run: false to actually merge.
#
# Usage:
#   Athletes::MergeDuplicates.new(verbose: true).call            # dry run
#   Athletes::MergeDuplicates.new(dry_run: false).call           # commit
class Athletes::MergeDuplicates
  SUFFIXES = %w[jr sr ii iii iv v].freeze

  attr_reader :stats

  def initialize(dry_run: true, verbose: false)
    @dry_run = dry_run
    @verbose = verbose
    @stats = Hash.new(0)
  end

  def call
    pairs = find_duplicate_pairs
    puts "Found #{pairs.size} duplicate-Person pair(s) (dry_run=#{@dry_run})"

    pairs.each do |duplicate, canonical|
      vputs "  #{duplicate.slug.ljust(28)} → #{canonical.slug}"
      if @dry_run
        @stats[:would_merge] += 1
      else
        merge!(duplicate, canonical)
        @stats[:merged] += 1
      end
    end

    puts "\nstats: #{@stats.inspect}"
    @stats
  end

  # Returns Array of [duplicate_person, canonical_person]. Public so callers
  # can preview without invoking #call.
  def find_duplicate_pairs
    pairs = []
    Person.where(athlete: true).find_each do |dup|
      ath = dup.athlete_profile
      next unless ath
      next if has_any_id?(ath)

      suffix_slugs = SUFFIXES.map { |s| "#{dup.slug}-#{s}" }
      canonical = Person.where(slug: suffix_slugs)
                        .includes(:athlete_profile)
                        .find { |c| has_any_id?(c.athlete_profile) }
      pairs << [dup, canonical] if canonical
    end
    pairs
  end

  private

  def has_any_id?(athlete)
    return false unless athlete
    [athlete.gsis_id, athlete.pff_id, athlete.espn_id, athlete.otc_id, athlete.pfr_id].any?(&:present?)
  end

  def merge!(duplicate, canonical)
    dup_athlete = duplicate.athlete_profile
    can_athlete = canonical.athlete_profile

    ActiveRecord::Base.transaction do
      move_grades(dup_athlete, can_athlete)
      move_pff_stats(dup_athlete, can_athlete)
      move_image_caches(dup_athlete, can_athlete)
      move_contracts(duplicate, canonical)
      move_depth_chart_entries(duplicate, canonical)
      move_roster_spots(duplicate, canonical)

      dup_athlete.destroy
      duplicate.destroy
    end
  end

  def move_grades(dup_athlete, can_athlete)
    AthleteGrade.where(athlete_slug: dup_athlete.slug).find_each do |g|
      conflict = AthleteGrade.find_by(athlete_slug: can_athlete.slug, season_slug: g.season_slug)
      if conflict
        g.destroy
        @stats[:grades_dropped] += 1
      else
        g.update!(athlete_slug: can_athlete.slug)
        @stats[:grades_moved] += 1
      end
    end
  end

  def move_pff_stats(dup_athlete, can_athlete)
    PffStat.where(athlete_slug: dup_athlete.slug).find_each do |s|
      conflict = PffStat.find_by(athlete_slug: can_athlete.slug, season_slug: s.season_slug, stat_type: s.stat_type)
      if conflict
        s.destroy
        @stats[:pff_stats_dropped] += 1
      else
        s.update!(athlete_slug: can_athlete.slug)
        @stats[:pff_stats_moved] += 1
      end
    end
  end

  def move_image_caches(dup_athlete, can_athlete)
    ImageCache.where(owner: dup_athlete).find_each do |c|
      conflict = ImageCache.find_by(owner: can_athlete, purpose: c.purpose, variant: c.variant)
      if conflict
        c.destroy
        @stats[:image_caches_dropped] += 1
      else
        c.update!(owner: can_athlete)
        @stats[:image_caches_moved] += 1
      end
    end
  end

  def move_contracts(duplicate, canonical)
    duplicate.contracts.each do |c|
      conflict = Contract.find_by(person_slug: canonical.slug, team_slug: c.team_slug)
      if conflict
        c.destroy
        @stats[:contracts_dropped] += 1
      else
        c.update!(person_slug: canonical.slug)
        @stats[:contracts_moved] += 1
      end
    end
  end

  def move_depth_chart_entries(duplicate, canonical)
    DepthChartEntry.where(person_slug: duplicate.slug).find_each do |e|
      conflict = DepthChartEntry.find_by(depth_chart_slug: e.depth_chart_slug,
                                          person_slug: canonical.slug,
                                          position: e.position)
      if conflict
        e.destroy
        @stats[:depth_chart_entries_dropped] += 1
      else
        e.update!(person_slug: canonical.slug)
        @stats[:depth_chart_entries_moved] += 1
      end
    end
  end

  def move_roster_spots(duplicate, canonical)
    RosterSpot.where(person_slug: duplicate.slug).find_each do |rs|
      conflict = RosterSpot.find_by(roster_id: rs.roster_id, person_slug: canonical.slug, position: rs.position)
      if conflict
        rs.destroy
        @stats[:roster_spots_dropped] += 1
      else
        rs.update!(person_slug: canonical.slug)
        @stats[:roster_spots_moved] += 1
      end
    end
  end

  def vputs(msg)
    puts msg if @verbose
  end
end
