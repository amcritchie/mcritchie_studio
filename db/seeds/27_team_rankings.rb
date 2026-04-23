season = Season.find_by(year: 2025, league: "nfl")
if season
  TeamRanking.compute_all!(season_slug: season.slug)
  puts "  TeamRankings: #{TeamRanking.count} computed"
else
  puts "  TeamRankings: skipped (no 2025 NFL season)"
end
