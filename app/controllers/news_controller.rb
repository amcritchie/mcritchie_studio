class NewsController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
  skip_before_action :require_authentication, only: [:index, :show, :workflow]
  before_action :require_admin, except: [:index, :show, :workflow]
  before_action :set_news, only: [:show, :edit, :update, :destroy, :archive, :review, :process_step, :refine, :conclude, :create_content]

  def index
    @news_items = News.ordered
    @news_by_stage = @news_items.group_by(&:stage)
  end

  def show
  end

  def workflow
  end

  def new
    @news = News.new
  end

  def create
    @news = News.new(news_params)
    rescue_and_log(target: @news) do
      @news.save!
      redirect_to news_path(@news.slug), notice: "News created."
    end
  rescue StandardError => e
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    rescue_and_log(target: @news) do
      @news.update!(news_params)
      respond_to do |format|
        format.html { redirect_to news_path(@news.slug), notice: "News updated." }
        format.json { render json: @news }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def destroy
    rescue_and_log(target: @news) do
      @news.destroy!
      respond_to do |format|
        format.html { redirect_to news_index_path, notice: "News deleted." }
        format.json { head :no_content }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to news_index_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def archive
    rescue_and_log(target: @news) do
      @news.archive!
      respond_to do |format|
        format.html { redirect_to news_path(@news.slug), notice: "News archived." }
        format.json { render json: @news }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to news_path(@news.slug), alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def review
    rescue_and_log(target: @news) do
      raise "News must be in new stage" unless @news.stage == "new"

      News::Review.new(@news).call(
        primary_person: params[:primary_person],
        primary_team: params[:primary_team],
        primary_action: params[:primary_action],
        secondary_person: params[:secondary_person],
        secondary_team: params[:secondary_team],
        article_image_url: params[:article_image_url]
      )
      redirect_to news_path(@news.slug), notice: "Reviewed — people and teams identified."
    end
  rescue StandardError => e
    redirect_to news_path(@news.slug), alert: e.message
  end

  def process_step
    rescue_and_log(target: @news) do
      raise "News must be in reviewed stage" unless @news.stage == "reviewed"

      News::Process.new(@news).call
      respond_to do |format|
        format.html { redirect_to news_path(@news.slug), notice: "Processed — slugs generated." }
        format.json { render json: @news }
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to news_path(@news.slug), alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def refine
    rescue_and_log(target: @news) do
      raise "News must be in processed stage" unless @news.stage == "processed"

      News::RefineAgent.new(@news).call
      redirect_to news_path(@news.slug), notice: "Refined — summary and feeling generated."
    end
  rescue StandardError => e
    redirect_to news_path(@news.slug), alert: e.message
  end

  def conclude
    rescue_and_log(target: @news) do
      raise "News must be in refined stage" unless @news.stage == "refined"

      News::ConcludeAgent.new(@news).call
      redirect_to news_path(@news.slug), notice: "Concluded — opinion and callback generated."
    end
  rescue StandardError => e
    redirect_to news_path(@news.slug), alert: e.message
  end

  def create_content
    rescue_and_log(target: @news) do
      raise "News must be in concluded stage" unless @news.stage == "concluded"

      content = Content.create!(
        title: "#{@news.title_short.presence || @news.title} — TikTok",
        description: @news.summary,
        source_type: "news",
        source_news_slug: @news.slug
      )
      redirect_to content_path(content.slug), notice: "Content idea created from news."
    end
  rescue StandardError => e
    redirect_to news_path(@news.slug), alert: e.message
  end

  def reorder
    slugs = params[:slugs]
    return render json: { error: "slugs required" }, status: :unprocessable_entity unless slugs.is_a?(Array)

    rescue_and_log(target: nil) do
      slugs.each_with_index do |slug, index|
        News.where(slug: slug).update_all(position: (slugs.length - index) * 100)
      end
      render json: { success: true }
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_news
    @news = News.find_by(slug: params[:slug])
    return redirect_to news_index_path, alert: "News not found" unless @news
  end

  def news_params
    params.require(:news).permit(
      :title, :url, :x_post_id, :x_post_url, :author, :published_at, :stage,
      :primary_person, :primary_team, :primary_action, :secondary_person, :secondary_team, :article_image_url,
      :primary_person_slug, :primary_team_slug, :secondary_person_slug, :secondary_team_slug,
      :title_short, :summary, :feeling, :feeling_emoji, :what_happened,
      :opinion, :callback
    )
  end
end
