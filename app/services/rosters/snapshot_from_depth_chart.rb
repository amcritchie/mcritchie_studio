module Rosters
  # Snapshots the current DepthChart + DepthChartEntry state of every NFL team
  # into per-slate Roster + RosterSpot rows.
  #
  # Why: DepthChart is season-agnostic ("what's true right now"). Rosters are
  # per-slate snapshots (what was true for Week 3 of 2026). The game show page
  # reads from per-slate Rosters, so we need to materialize them.
  #
  # Idempotent: re-running over an existing slate updates RosterSpot rows in
  # place (handles depth-chart changes since the last snapshot).
  #
  # Usage:
  #   Rosters::SnapshotFromDepthChart.new(slate_slug: "2026-nfl-week-1").call
  #   #=> { teams_snapshotted: 32, teams_without_chart: 0, spots_created: 1234, spots_updated: 0 }
  class SnapshotFromDepthChart
    def initialize(slate_slug:, verbose: false)
      @slate_slug = slate_slug
      @verbose = verbose
      @stats = Hash.new(0)
    end

    def call
      slate = Slate.find_by!(slug: @slate_slug)

      Team.where(league: "nfl").includes(depth_chart: :depth_chart_entries).find_each do |team|
        chart = team.depth_chart
        unless chart
          @stats[:teams_without_chart] += 1
          vputs "  [!] #{team.short_name}: no DepthChart — skipping"
          next
        end

        roster = Roster.find_or_create_by!(team_slug: team.slug, slate_slug: slate.slug)

        chart.depth_chart_entries.find_each do |entry|
          spot = RosterSpot.find_or_initialize_by(roster: roster, position: entry.position, depth: entry.depth)
          if spot.new_record?
            spot.person_slug = entry.person_slug
            spot.side = entry.side
            spot.save!
            @stats[:spots_created] += 1
          elsif spot.person_slug != entry.person_slug || spot.side != entry.side
            spot.update!(person_slug: entry.person_slug, side: entry.side)
            @stats[:spots_updated] += 1
          end
        end

        @stats[:teams_snapshotted] += 1
        vputs "  [+] #{team.short_name}: #{roster.roster_spots.count} spots for #{slate.slug}"
      end

      @stats
    end

    private

    def vputs(msg)
      puts msg if @verbose
    end
  end
end
