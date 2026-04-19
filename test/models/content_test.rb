require "test_helper"

class ContentTest < ActiveSupport::TestCase
  # --- Slug ---

  test "slug is generated on create" do
    content = Content.create!(title: "Test slug generation")
    assert content.slug.present?
    assert content.slug.start_with?("content-")
  end

  test "slug is immutable after creation" do
    content = contents(:idea_content)
    original_slug = content.slug
    content.update!(title: "Changed title")
    assert_equal original_slug, content.slug
  end

  test "to_param returns slug" do
    content = contents(:idea_content)
    assert_equal content.slug, content.to_param
  end

  # --- Stage transitions ---

  test "idea content can be hooked" do
    content = contents(:idea_content)
    content.hook!
    assert_equal "hook", content.stage
    assert_not_nil content.hooked_at
  end

  test "hook content can be scripted" do
    content = contents(:hook_content)
    content.script!
    assert_equal "script", content.stage
    assert_not_nil content.scripted_at
  end

  test "script content can get assets" do
    content = contents(:script_content)
    content.assets!
    assert_equal "assets", content.stage
    assert_not_nil content.asset_at
  end

  test "assets content can be assembled" do
    content = Content.create!(title: "Assets test", stage: "assets")
    content.assemble!
    assert_equal "assembly", content.stage
    assert_not_nil content.assembled_at
  end

  test "assembly content can be posted" do
    content = Content.create!(title: "Assembly test", stage: "assembly")
    content.post!
    assert_equal "posted", content.stage
    assert_not_nil content.posted_at
  end

  test "posted content can be reviewed" do
    content = contents(:posted_content)
    content.review!
    assert_equal "reviewed", content.stage
    assert_not_nil content.reviewed_at
  end

  # --- Position ---

  test "position is auto-set on create" do
    content = Content.create!(title: "Auto position test", stage: "idea")
    assert_not_nil content.position
  end

  test "stage change gives highest position in target stage" do
    content = contents(:idea_content)
    existing = Content.where(stage: "hook").maximum(:position) || 0
    content.update!(stage: "hook")
    assert_equal "hook", content.stage
    assert_equal existing + 100, content.position
  end

  test "new contents get appended to end of stage" do
    c1 = Content.create!(title: "First", stage: "idea")
    c2 = Content.create!(title: "Second", stage: "idea")
    assert c2.position > c1.position
  end

  # --- Validations ---

  test "title is required" do
    content = Content.new(title: nil)
    assert_not content.valid?
    assert_includes content.errors[:title], "can't be blank"
  end

  test "stage must be valid" do
    content = contents(:idea_content)
    assert_raises ActiveRecord::RecordInvalid do
      content.update!(stage: "invalid_stage")
    end
  end

  # --- Scopes ---

  test "by_stage returns only matching stage" do
    results = Content.by_stage("idea")
    results.each { |c| assert_equal "idea", c.stage }
  end

  test "ordered scope returns records" do
    results = Content.ordered
    assert results.any?
  end

  # --- Source News association ---

  test "source_news association works" do
    content = contents(:posted_content)
    if content.source_news_slug.present?
      news = News.find_by(slug: content.source_news_slug)
      assert_equal news, content.source_news if news
    end
  end

  # --- Service: Content::Hook ---

  test "Hook service updates fields and advances stage" do
    content = contents(:idea_content)
    result = Content::Hook.new(content).call(
      hook_image_url: "https://example.com/hook.jpg",
      hook_ideas: ["Hook 1", "Hook 2", "Hook 3"],
      selected_hook_index: 0
    )

    assert_equal "hook", result.stage
    assert_equal "https://example.com/hook.jpg", result.hook_image_url
    assert_equal ["Hook 1", "Hook 2", "Hook 3"], result.hook_ideas
    assert_equal 0, result.selected_hook_index
    assert_not_nil result.hooked_at
  end

  # --- Service: Content::Script ---

  test "Script service updates fields and advances stage" do
    content = contents(:hook_content)
    result = Content::Script.new(content).call(
      script_text: "This is the script.",
      duration_seconds: 30,
      scenes: [{ "scene_number" => 1, "description" => "Opener" }]
    )

    assert_equal "script", result.stage
    assert_equal "This is the script.", result.script_text
    assert_equal 30, result.duration_seconds
    assert_equal 1, result.scenes.length
    assert_not_nil result.scripted_at
  end

  # --- Service: Content::Assets ---

  test "Assets service updates fields and advances stage" do
    content = contents(:script_content)
    result = Content::Assets.new(content).call(
      scene_assets: [{ "scene_number" => 1, "image_url" => "https://example.com/1.jpg", "status" => "ready" }]
    )

    assert_equal "assets", result.stage
    assert_equal 1, result.scene_assets.length
    assert_not_nil result.asset_at
  end

  # --- Service: Content::Assemble ---

  test "Assemble service updates fields and advances stage" do
    content = Content.create!(title: "Assemble test", stage: "assets")
    result = Content::Assemble.new(content).call(
      final_video_url: "https://example.com/video.mp4",
      music_track: "epic_beat.mp3",
      text_overlays: [{ "text" => "Hello" }],
      logo_overlay: true
    )

    assert_equal "assembly", result.stage
    assert_equal "https://example.com/video.mp4", result.final_video_url
    assert_equal "epic_beat.mp3", result.music_track
    assert_not_nil result.assembled_at
  end

  # --- Service: Content::Post ---

  test "Post service updates fields and advances stage" do
    content = Content.create!(title: "Post test", stage: "assembly")
    result = Content::Post.new(content).call(
      platform: "tiktok",
      post_url: "https://tiktok.com/@test/video/123",
      post_id: "123"
    )

    assert_equal "posted", result.stage
    assert_equal "https://tiktok.com/@test/video/123", result.post_url
    assert_equal "123", result.post_id
    assert_not_nil result.posted_at
  end

  # --- Service: Content::Review ---

  test "Review service updates fields and advances stage" do
    content = contents(:posted_content)
    result = Content::Review.new(content).call(
      views: 10000,
      likes: 500,
      comments_count: 50,
      shares: 100,
      review_notes: "Great engagement."
    )

    assert_equal "reviewed", result.stage
    assert_equal 10000, result.views
    assert_equal 500, result.likes
    assert_equal 50, result.comments_count
    assert_equal 100, result.shares
    assert_equal "Great engagement.", result.review_notes
    assert_not_nil result.reviewed_at
  end

  # --- Full pipeline ---

  test "full pipeline idea through reviewed" do
    content = Content.create!(title: "Pipeline test", description: "Testing full flow")

    Content::Hook.new(content).call(
      hook_image_url: "https://example.com/hook.jpg",
      hook_ideas: ["A", "B", "C"],
      selected_hook_index: 1
    )
    assert_equal "hook", content.stage

    Content::Script.new(content).call(
      script_text: "Full script here.",
      duration_seconds: 30,
      scenes: [{ "scene_number" => 1, "description" => "Scene 1" }]
    )
    assert_equal "script", content.stage

    Content::Assets.new(content).call(
      scene_assets: [{ "scene_number" => 1, "image_url" => "https://example.com/1.jpg" }]
    )
    assert_equal "assets", content.stage

    Content::Assemble.new(content).call(
      final_video_url: "https://example.com/final.mp4",
      music_track: "track.mp3",
      text_overlays: [],
      logo_overlay: true
    )
    assert_equal "assembly", content.stage

    Content::Post.new(content).call(
      platform: "tiktok",
      post_url: "https://tiktok.com/@test/video/999",
      post_id: "999"
    )
    assert_equal "posted", content.stage

    Content::Review.new(content).call(
      views: 5000,
      likes: 250,
      comments_count: 30,
      shares: 75,
      review_notes: "Solid performance."
    )
    assert_equal "reviewed", content.stage
  end
end
