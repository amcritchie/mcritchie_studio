require "test_helper"

class Athletes::MergeDuplicatesTest < ActiveSupport::TestCase
  setup do
    @bills = teams(:buffalo_bills)
  end

  def make_pair(slug_base: "test-player", suffix: "jr")
    canonical = Person.create!(first_name: "Test", last_name: "Player #{suffix.upcase}", athlete: true)
    canonical.update!(slug: "#{slug_base}-#{suffix}")
    canonical_athlete = Athlete.create!(person_slug: canonical.slug, sport: "football",
                                         position: "QB", gsis_id: "00-#{rand(1_000_000..9_999_999)}",
                                         pff_id: rand(100_000..999_999))

    duplicate = Person.create!(first_name: "Test", last_name: "Player", athlete: true)
    duplicate.update!(slug: slug_base)
    duplicate_athlete = Athlete.create!(person_slug: duplicate.slug, sport: "football", position: "QB")

    [duplicate, canonical, duplicate_athlete, canonical_athlete]
  end

  test "find_duplicate_pairs identifies suffix-variant pairs where canonical has IDs" do
    duplicate, canonical, _, _ = make_pair

    pairs = Athletes::MergeDuplicates.new.find_duplicate_pairs
    assert_includes pairs.map { |d, c| [d.slug, c.slug] }, [duplicate.slug, canonical.slug]
  end

  test "find_duplicate_pairs detects same-name siblings with different slugs" do
    # Two Persons with the same first+last but distinct slugs. Happens when
    # data sources produce different parameterizations (punctuation, etc.) —
    # we simulate by creating one Person, then mutating another to share
    # first+last via update_column (bypasses Sluggable's before_save).
    canonical = Person.create!(first_name: "Test", last_name: "Sibling", athlete: true)
    Athlete.create!(person_slug: canonical.slug, sport: "football", gsis_id: "00-9999993")

    duplicate = Person.create!(first_name: "Test", last_name: "Variant", athlete: true)
    duplicate.update_column(:last_name, "Sibling")  # now matches canonical's first+last
    Athlete.create!(person_slug: duplicate.slug, sport: "football")

    pairs = Athletes::MergeDuplicates.new.find_duplicate_pairs
    assert_includes pairs.map { |d, c| [d.slug, c.slug] }, [duplicate.slug, canonical.slug]
  end

  test "find_duplicate_pairs ignores Persons that already have IDs" do
    duplicate, _canonical, dup_athlete, _ = make_pair
    dup_athlete.update!(gsis_id: "00-9999998")

    pairs = Athletes::MergeDuplicates.new.find_duplicate_pairs
    refute_includes pairs.map { |d, _| d.slug }, duplicate.slug
  end

  test "dry_run does not destroy or move records" do
    duplicate, _canonical, _, _ = make_pair
    assert Person.exists?(slug: duplicate.slug)

    service = Athletes::MergeDuplicates.new(dry_run: true)
    service.call

    assert Person.exists?(slug: duplicate.slug), "duplicate should still exist after dry run"
    assert_equal 0, service.stats[:merged]
    assert service.stats[:would_merge] >= 1
  end

  test "non-dry-run merges contracts to canonical" do
    duplicate, canonical, _, _ = make_pair
    Contract.create!(person_slug: duplicate.slug, team_slug: @bills.slug,
                     contract_type: "active", position: "QB")

    service = Athletes::MergeDuplicates.new(dry_run: false)
    service.call

    refute Person.exists?(slug: duplicate.slug)
    assert Contract.exists?(person_slug: canonical.slug, team_slug: @bills.slug)
    assert_equal 1, service.stats[:contracts_moved]
  end

  test "non-dry-run drops duplicate contract when canonical already has one for same team" do
    duplicate, canonical, _, _ = make_pair
    Contract.create!(person_slug: canonical.slug, team_slug: @bills.slug, contract_type: "active", position: "QB")
    Contract.create!(person_slug: duplicate.slug, team_slug: @bills.slug, contract_type: "active", position: "QB")

    service = Athletes::MergeDuplicates.new(dry_run: false)
    service.call

    # Canonical's contract preserved; duplicate's dropped
    assert_equal 1, Contract.where(person_slug: canonical.slug, team_slug: @bills.slug).count
    assert_equal 1, service.stats[:contracts_dropped]
  end

  test "non-dry-run moves depth chart entries (with conflict drop)" do
    duplicate, canonical, _, _ = make_pair
    chart = DepthChart.find_or_create_by!(team_slug: @bills.slug)
    DepthChartEntry.create!(depth_chart_slug: chart.slug, person_slug: duplicate.slug,
                            position: "QB", side: "offense", depth: 1)

    Athletes::MergeDuplicates.new(dry_run: false).call

    assert DepthChartEntry.exists?(depth_chart_slug: chart.slug, person_slug: canonical.slug, position: "QB")
    refute DepthChartEntry.exists?(depth_chart_slug: chart.slug, person_slug: duplicate.slug, position: "QB")
  end

  test "non-dry-run moves grades (with conflict drop)" do
    _, _canonical, dup_athlete, can_athlete = make_pair
    AthleteGrade.create!(athlete_slug: dup_athlete.slug, season_slug: "2025-nfl", overall_grade_pff: 70.0)

    Athletes::MergeDuplicates.new(dry_run: false).call

    assert AthleteGrade.exists?(athlete_slug: can_athlete.slug, season_slug: "2025-nfl")
    refute AthleteGrade.exists?(athlete_slug: dup_athlete.slug)
  end

  test "non-dry-run moves image_caches (with conflict drop)" do
    _, _canonical, dup_athlete, can_athlete = make_pair
    ImageCache.create!(owner: dup_athlete, purpose: "headshot", variant: "100",
                       s3_key: "test/dup-100.png", source_url: "http://x", bytes: 1, content_type: "image/png")

    Athletes::MergeDuplicates.new(dry_run: false).call

    assert ImageCache.exists?(owner_id: can_athlete.id, owner_type: "Athlete", variant: "100")
  end
end
