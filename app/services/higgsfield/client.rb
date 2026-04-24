require "net/http"
require "json"

module Higgsfield
  class Client
    BASE_URL = "https://platform.higgsfield.ai"
    POLL_INTERVAL = 3 # seconds
    MAX_POLL_TIME = 300 # 5 minutes

    class GenerationError < StandardError; end
    class TimeoutError < StandardError; end

    def initialize
      @api_key = ENV["HIGGSFIELD_API_KEY"]
      @api_secret = ENV["HIGGSFIELD_API_SECRET"]
      raise GenerationError, "HIGGSFIELD_API_KEY not set" if @api_key.blank?
      raise GenerationError, "HIGGSFIELD_API_SECRET not set" if @api_secret.blank?
    end

    # Generate image via Soul model
    # Returns { "job_set_id" => "...", ... }
    def generate_image(prompt:, width_and_height: "1024x1792", quality: "1080p", enhance_prompt: true)
      post("/v1/text2image/soul", {
        params: {
          prompt: prompt,
          width_and_height: width_and_height,
          quality: quality,
          batch_size: 1,
          enhance_prompt: enhance_prompt
        }
      })
    end

    # Generate video from image via DoP model
    # Returns { "job_set_id" => "...", ... }
    def generate_video(image_url:, prompt:, model: "dop-turbo", motion_id: nil, motion_strength: 0.5)
      params = {
        model: model,
        prompt: prompt,
        input_images: [{ type: "image_url", image_url: image_url }]
      }
      params[:motions] = [{ id: motion_id, strength: motion_strength }] if motion_id.present?

      post("/v1/image2video/dop", { params: params })
    end

    # Poll until job completes. Returns the full job set response.
    def wait_for_completion(job_set_id)
      started_at = Time.current
      loop do
        elapsed = Time.current - started_at
        raise TimeoutError, "Higgsfield job #{job_set_id} timed out after #{MAX_POLL_TIME}s" if elapsed > MAX_POLL_TIME

        result = get("/v1/job-sets/#{job_set_id}")
        jobs = result["jobs"] || []

        if jobs.all? { |j| terminal_status?(j["status"]) }
          failed = jobs.select { |j| j["status"] == "failed" }
          if failed.any?
            raise GenerationError, "Higgsfield job failed: #{failed.map { |j| j["error"] || j["status"] }.join(", ")}"
          end
          nsfw = jobs.select { |j| j["status"] == "nsfw" }
          if nsfw.any?
            raise GenerationError, "Higgsfield job flagged as NSFW"
          end
          return result
        end

        sleep POLL_INTERVAL
      end
    end

    # Convenience: submit + poll, return result URL
    def generate_image_and_wait(prompt:, width_and_height: "1024x1792", quality: "1080p", enhance_prompt: true)
      response = generate_image(prompt: prompt, width_and_height: width_and_height, quality: quality, enhance_prompt: enhance_prompt)
      job_set_id = response["id"] || response["job_set_id"]
      raise GenerationError, "No job_set_id in response: #{response.inspect}" unless job_set_id

      result = wait_for_completion(job_set_id)
      extract_result_url(result)
    end

    def generate_video_and_wait(image_url:, prompt:, model: "dop-turbo", motion_id: nil)
      response = generate_video(image_url: image_url, prompt: prompt, model: model, motion_id: motion_id)
      job_set_id = response["id"] || response["job_set_id"]
      raise GenerationError, "No job_set_id in response: #{response.inspect}" unless job_set_id

      result = wait_for_completion(job_set_id)
      extract_result_url(result)
    end

    private

    def terminal_status?(status)
      %w[completed failed nsfw cancelled].include?(status&.downcase)
    end

    def extract_result_url(result)
      job = (result["jobs"] || []).find { |j| j["status"]&.downcase == "completed" }
      raise GenerationError, "No completed job in result" unless job

      # Try raw (full quality) first, fall back to min (preview)
      url = job.dig("results", "raw", "url") || job.dig("results", "min", "url")
      raise GenerationError, "No result URL in completed job: #{job.inspect}" unless url

      url
    end

    def headers
      {
        "hf-api-key" => @api_key,
        "hf-secret" => @api_secret,
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end

    def post(path, body)
      uri = URI("#{BASE_URL}#{path}")
      http = build_http(uri)

      request = Net::HTTP::Post.new(uri.path, headers)
      request.body = body.to_json

      execute(http, request, path)
    end

    def get(path)
      uri = URI("#{BASE_URL}#{path}")
      http = build_http(uri)

      request = Net::HTTP::Get.new(uri.path, headers)

      execute(http, request, path)
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10
      http
    end

    def execute(http, request, path)
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise GenerationError, "Higgsfield API error on #{path}: #{response.code} — #{response.body.to_s.truncate(500)}"
      end

      JSON.parse(response.body)
    end
  end
end
