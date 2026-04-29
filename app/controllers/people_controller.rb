class PeopleController < ApplicationController
  skip_before_action :require_authentication, only: [:index]

  def index
    @people = Person.includes(:teams, { athlete_profile: :image_caches }, contracts: :team).order(:last_name, :first_name)
  end

  def search
    query = params[:q].to_s.strip
    people = if query.present?
      Person.where("first_name ILIKE :q OR last_name ILIKE :q OR slug ILIKE :q OR aliases::text ILIKE :q",
                    q: "%#{query}%")
            .order(created_at: :desc)
            .limit(20)
    else
      Person.order(created_at: :desc).limit(10)
    end

    render json: people.map { |p|
      { id: p.id, slug: p.slug, full_name: p.full_name, aliases: p.aliases, teams: p.teams.pluck(:name) }
    }
  end

  def merge
    # Render merge form
  end

  def merge_execute
    keep = Person.find_by(slug: params[:keep_slug])
    merge_person = Person.find_by(slug: params[:merge_slug])

    unless keep && merge_person
      return redirect_to merge_people_path, alert: "Both people must be selected."
    end

    if keep == merge_person
      return redirect_to merge_people_path, alert: "Cannot merge a person into themselves."
    end

    rescue_and_log(target: merge_person, parent: keep) do
      perform_merge!(keep, merge_person)
      redirect_to people_path, notice: "Merged #{merge_person.full_name} into #{keep.full_name}."
    end
  rescue StandardError => e
    redirect_to merge_people_path, alert: "Merge failed: #{e.message}"
  end

  def duplicates
    @duplicate_groups = find_duplicate_groups
  end

  private

  def perform_merge!(keep, source)
    # 1. Move contracts
    source.contracts.each do |c|
      existing = Contract.find_by(person_slug: keep.slug, team_slug: c.team_slug)
      if existing
        c.destroy!
      else
        c.update!(person_slug: keep.slug, slug: "#{keep.slug}-#{c.team_slug}")
      end
    end

    # 2. Move roster spots
    source.roster_spots.update_all(person_slug: keep.slug)

    # 3. Move coaches
    source.coaches.each do |c|
      existing = Coach.find_by(person_slug: keep.slug, team_slug: c.team_slug, role: c.role)
      if existing
        c.destroy!
      else
        c.update!(person_slug: keep.slug)
      end
    end

    # 4. Merge athlete profiles
    source_athlete = source.athlete_profile
    keep_athlete = keep.athlete_profile

    if source_athlete
      if keep_athlete
        # Merge draft data into keep's athlete if keep is missing it
        if keep_athlete.draft_pick.nil? && source_athlete.draft_pick.present?
          keep_athlete.update!(
            draft_year: source_athlete.draft_year,
            draft_round: source_athlete.draft_round,
            draft_pick: source_athlete.draft_pick
          )
        end
        # Move athlete grades from source to keep
        source_athlete.grades.each do |g|
          existing = AthleteGrade.find_by(athlete_slug: keep_athlete.slug, season_slug: g.season_slug)
          if existing
            g.destroy!
          else
            g.update!(athlete_slug: keep_athlete.slug)
          end
        end
        # Move pff_stats
        source_athlete.pff_stats.each do |s|
          existing = PffStat.find_by(athlete_slug: keep_athlete.slug, season_slug: s.season_slug, stat_type: s.stat_type)
          if existing
            s.destroy!
          else
            s.update!(athlete_slug: keep_athlete.slug)
          end
        end
        source_athlete.destroy!
      else
        # Re-parent the athlete
        source_athlete.update!(person_slug: keep.slug)
      end
    end

    # 5. Add merged person's name as alias
    alias_name = source.full_name
    unless keep.aliases.include?(alias_name)
      keep.aliases << alias_name
    end
    # Also merge in source's aliases
    source.aliases.each do |a|
      keep.aliases << a unless keep.aliases.include?(a)
    end
    keep.save!

    # 6. Copy boolean flags
    keep.update!(athlete: true) if source.athlete? && !keep.athlete?
    keep.update!(coach: true) if source.coach? && !keep.coach?

    # 7. Delete merged person
    source.destroy!
  end

  def find_duplicate_groups
    # Find people who share last_name and have similar first names (Levenshtein ≤ 2)
    groups = []

    # Group athletes by last_name + position
    people_with_athletes = Person.includes(:athlete_profile).where(athlete: true).order(:last_name, :first_name)
    by_last_name = people_with_athletes.group_by(&:last_name)

    by_last_name.each do |last_name, people|
      next if people.size < 2

      people.combination(2).each do |a, b|
        dist = levenshtein(a.first_name.downcase, b.first_name.downcase)
        if dist > 0 && dist <= 2
          groups << { people: [a, b], distance: dist, last_name: last_name }
        end
      end
    end

    groups.sort_by { |g| [g[:distance], g[:last_name]] }
  end

  def levenshtein(a, b)
    m = a.length
    n = b.length
    return n if m == 0
    return m if n == 0

    d = Array.new(m + 1) { Array.new(n + 1, 0) }
    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }

    (1..m).each do |i|
      (1..n).each do |j|
        cost = a[i - 1] == b[j - 1] ? 0 : 1
        d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].min
      end
    end

    d[m][n]
  end
end
