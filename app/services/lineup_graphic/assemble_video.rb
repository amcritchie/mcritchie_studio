require "open3"

module LineupGraphic
  # Assembles a sequence of PNG frames captured by `script/capture_lineup.js`
  # into an X-compatible MP4. Caps output at 30fps (X's video spec is ≤60fps;
  # CDP screencast often delivers 60–80fps which gets rejected as "media IDs invalid").
  module AssembleVideo
    OUTPUT_WIDTH  = 1200
    OUTPUT_HEIGHT = 1500
    OUTPUT_FPS    = 30
    CRF           = "16"

    class Error < StandardError; end

    # Runs ffmpeg synchronously. Raises on non-zero exit.
    def self.call(frames_dir:, output_mp4:)
      pattern  = File.join(frames_dir.to_s, "frame_%05d.png")
      fps_file = File.join(frames_dir.to_s, "framerate.txt")
      input_fps = File.exist?(fps_file) ? File.read(fps_file).strip : OUTPUT_FPS.to_s

      cmd = [
        "ffmpeg", "-y",
        "-framerate", input_fps,
        "-i", pattern,
        "-vf", "fps=#{OUTPUT_FPS},scale=#{OUTPUT_WIDTH}:#{OUTPUT_HEIGHT}:flags=lanczos",
        "-c:v", "libx264",
        "-crf", CRF,
        "-preset", "slow",
        "-pix_fmt", "yuv420p",
        "-movflags", "+faststart",
        output_mp4.to_s
      ]
      out, status = Open3.capture2e(*cmd)
      raise Error, "ffmpeg failed (#{status.exitstatus}):\n#{out.last(800)}" unless status.success?
      output_mp4.to_s
    end
  end
end
