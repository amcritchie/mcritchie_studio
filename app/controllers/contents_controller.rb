class ContentsController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
  skip_before_action :require_authentication, only: [:index, :show]
  before_action :require_admin, except: [:index, :show]
  before_action :set_content, only: [:show, :edit, :update, :destroy, :hook_step, :script_step, :assets_step, :assemble_step, :post_step, :review_step]

  def index
    @contents = Content.ordered
    @contents_by_stage = @contents.group_by(&:stage)
  end

  def show
  end

  def new
    @content = Content.new
  end

  def create
    @content = Content.new(content_params)
    rescue_and_log(target: @content) do
      @content.save!
      redirect_to content_path(@content.slug), notice: "Content idea created."
    end
  rescue StandardError => e
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    rescue_and_log(target: @content) do
      @content.update!(content_params)
      respond_to do |format|
        format.html { redirect_to content_path(@content.slug), notice: "Content updated." }
        format.json { render json: @content }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def destroy
    rescue_and_log(target: @content) do
      @content.destroy!
      respond_to do |format|
        format.html { redirect_to contents_path, notice: "Content deleted." }
        format.json { head :no_content }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to contents_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def reorder
    slugs = params[:slugs]
    return render json: { error: "slugs required" }, status: :unprocessable_entity unless slugs.is_a?(Array)

    rescue_and_log(target: nil) do
      slugs.each_with_index do |slug, index|
        Content.where(slug: slug).update_all(position: (slugs.length - index) * 100)
      end
      render json: { success: true }
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def hook_step
    rescue_and_log(target: @content) do
      raise "Content must be in idea stage" unless @content.stage == "idea"

      Content::Hook.new(@content).call(
        hook_image_url: params[:hook_image_url],
        hook_ideas: params[:hook_ideas],
        selected_hook_index: params[:selected_hook_index]&.to_i
      )
      redirect_to content_path(@content.slug), notice: "Hook created."
    end
  rescue StandardError => e
    redirect_to content_path(@content.slug), alert: e.message
  end

  def script_step
    rescue_and_log(target: @content) do
      raise "Content must be in hook stage" unless @content.stage == "hook"

      Content::Script.new(@content).call(
        script_text: params[:script_text],
        duration_seconds: params[:duration_seconds]&.to_i,
        scenes: params[:scenes]
      )
      redirect_to content_path(@content.slug), notice: "Script written."
    end
  rescue StandardError => e
    redirect_to content_path(@content.slug), alert: e.message
  end

  def assets_step
    rescue_and_log(target: @content) do
      raise "Content must be in script stage" unless @content.stage == "script"

      Content::Assets.new(@content).call(
        scene_assets: params[:scene_assets]
      )
      redirect_to content_path(@content.slug), notice: "Assets generated."
    end
  rescue StandardError => e
    redirect_to content_path(@content.slug), alert: e.message
  end

  def assemble_step
    rescue_and_log(target: @content) do
      raise "Content must be in assets stage" unless @content.stage == "assets"

      Content::Assemble.new(@content).call(
        final_video_url: params[:final_video_url],
        music_track: params[:music_track],
        text_overlays: params[:text_overlays],
        logo_overlay: params[:logo_overlay]
      )
      redirect_to content_path(@content.slug), notice: "Video assembled."
    end
  rescue StandardError => e
    redirect_to content_path(@content.slug), alert: e.message
  end

  def post_step
    rescue_and_log(target: @content) do
      raise "Content must be in assembly stage" unless @content.stage == "assembly"

      Content::Post.new(@content).call(
        platform: params[:platform],
        post_url: params[:post_url],
        post_id: params[:post_id]
      )
      redirect_to content_path(@content.slug), notice: "Content posted."
    end
  rescue StandardError => e
    redirect_to content_path(@content.slug), alert: e.message
  end

  def review_step
    rescue_and_log(target: @content) do
      raise "Content must be in posted stage" unless @content.stage == "posted"

      Content::Review.new(@content).call(
        views: params[:views]&.to_i,
        likes: params[:likes]&.to_i,
        comments_count: params[:comments_count]&.to_i,
        shares: params[:shares]&.to_i,
        review_notes: params[:review_notes]
      )
      redirect_to content_path(@content.slug), notice: "Content reviewed."
    end
  rescue StandardError => e
    redirect_to content_path(@content.slug), alert: e.message
  end

  private

  def set_content
    @content = Content.find_by(slug: params[:slug])
    return redirect_to contents_path, alert: "Content not found" unless @content
  end

  def content_params
    params.require(:content).permit(
      :title, :description, :source_type, :source_news_slug, :content_type, :stage,
      :hook_image_url, :selected_hook_index,
      :script_text, :duration_seconds,
      :final_video_url, :music_track, :logo_overlay,
      :platform, :post_url, :post_id,
      :views, :likes, :comments_count, :shares, :review_notes,
      :reference_video_url, :reference_video_start, :reference_video_end,
      :rival_team_slug, :captions,
      hashtags: [], music_suggestions: []
    )
  end
end
