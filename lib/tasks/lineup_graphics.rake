namespace :lineup_graphic do
  desc "Capture a team's lineup-graphic page as PNG + MP4 via CDP screencast. SLUG=buffalo-bills"
  task capture: :environment do
    slug = ENV["SLUG"] or abort("SLUG=team-slug required (e.g. SLUG=buffalo-bills)")
    base = ENV["BASE_URL"] || "http://localhost:3000"

    sh "node script/capture_lineup.js #{slug.shellescape} #{base.shellescape}"

    frames_dir = Rails.root.join("tmp", "lineup-graphics", "#{slug}-frames")
    mp4_path   = Rails.root.join("tmp", "lineup-graphics", "#{slug}.mp4")

    if Dir.glob(frames_dir.join("frame_*.png")).any?
      LineupGraphic::AssembleVideo.call(frames_dir: frames_dir, output_mp4: mp4_path)
      puts "mp4  → #{mp4_path}"
    else
      puts "no frames captured — skipping MP4 assembly"
    end
  end
end
