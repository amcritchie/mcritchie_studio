require "open3"

module LineupGraphic
  # Assembles a sequence of PNG frames captured by `script/capture_lineup.js`
  # into a social-platform-compatible MP4. Caps output at 30fps (X's video
  # spec is ≤60fps; CDP screencast often delivers 60–80fps which gets rejected
  # as "media IDs invalid").
  #
  # Optional `music_path:` muxes a royalty-free audio track into the MP4
  # (looped or trimmed to clip length). Use this for fully-automated TikTok
  # posts when you don't want to add a sound manually in the TikTok app.
  module AssembleVideo
    OUTPUT_FPS    = 30
    CRF           = "16"

    # Output dimensions per source side. CDP captures at 2× device pixels;
    # ffmpeg lanczos-downsamples to these targets.
    DIMENSIONS = {
      full:    { width: 1200, height: 1500 },  # X / 4:5
      offense: { width: 1080, height: 1920 },  # TikTok 9:16
      defense: { width: 1080, height: 1920 }   # TikTok 9:16
    }.freeze

    class Error < StandardError; end

    # Runs ffmpeg synchronously. Raises on non-zero exit. Auto-detects the
    # output dimensions by reading frame size if `side:` not provided
    # (defaults to :full for backward compat).
    def self.call(frames_dir:, output_mp4:, side: :full, music_path: nil)
      side = side.to_sym
      dims = DIMENSIONS.fetch(side) { DIMENSIONS[:full] }
      out_w = dims[:width]
      out_h = dims[:height]

      pattern  = File.join(frames_dir.to_s, "frame_%05d.png")
      fps_file = File.join(frames_dir.to_s, "framerate.txt")
      input_fps = File.exist?(fps_file) ? File.read(fps_file).strip : OUTPUT_FPS.to_s

      cmd = ["ffmpeg", "-y", "-framerate", input_fps, "-i", pattern]

      if music_path && File.exist?(music_path)
        # -stream_loop -1: loop the audio, then -shortest trims to video length.
        cmd += ["-stream_loop", "-1", "-i", music_path.to_s]
      end

      cmd += [
        "-vf", "fps=#{OUTPUT_FPS},scale=#{out_w}:#{out_h}:flags=lanczos",
        "-c:v", "libx264",
        "-crf", CRF,
        "-preset", "slow",
        "-pix_fmt", "yuv420p",
        "-movflags", "+faststart"
      ]

      if music_path && File.exist?(music_path)
        cmd += ["-c:a", "aac", "-b:a", "128k", "-shortest"]
      end

      cmd << output_mp4.to_s

      out, status = Open3.capture2e(*cmd)
      raise Error, "ffmpeg failed (#{status.exitstatus}):\n#{out.last(800)}" unless status.success?
      output_mp4.to_s
    end
  end
end
