class ExpenseUploadsController < ApplicationController
  before_action :require_admin
  before_action :set_upload, only: [:show, :destroy, :process_file, :evaluate]

  def index
    @uploads = ExpenseUpload.recent.includes(:user)
  end

  def new
    @upload = ExpenseUpload.new
  end

  def create
    @upload = ExpenseUpload.new(
      filename: params[:file]&.original_filename || "unknown",
      user: current_user,
      card_type: params[:card_type].presence
    )
    rescue_and_log(target: @upload) do
      @upload.save!
      @upload.file.attach(params[:file])
      redirect_to expense_upload_path(@upload.slug), notice: "File uploaded successfully."
    end
  rescue StandardError => e
    render :new, status: :unprocessable_entity
  end

  def show
    @transactions = @upload.expense_transactions.order(:transaction_date)
  end

  def destroy
    rescue_and_log(target: @upload) do
      @upload.destroy!
      redirect_to expense_uploads_path, notice: "Upload deleted."
    end
  rescue StandardError => e
    redirect_to expense_uploads_path, alert: e.message
  end

  def process_file
    rescue_and_log(target: @upload) do
      parser = Expenses::CsvParser.new(@upload)
      result = parser.parse

      @upload.update!(
        card_type: result.card_type || @upload.card_type,
        status: "processed",
        transaction_count: result.transactions.size,
        duplicates_skipped: result.duplicates_skipped,
        credits_skipped: result.credits_skipped,
        processing_summary: {
          errors: result.errors,
          processed_at: Time.current.iso8601
        },
        processed_at: Time.current
      )

      notice = "Processed #{result.transactions.size} transactions"
      notice += " (#{result.duplicates_skipped} duplicates skipped)" if result.duplicates_skipped > 0
      notice += " (#{result.credits_skipped} credits skipped)" if result.credits_skipped > 0
      redirect_to expense_upload_path(@upload.slug), notice: notice
    end
  rescue StandardError => e
    redirect_to expense_upload_path(@upload.slug), alert: "Processing failed: #{e.message}"
  end

  def evaluate
    rescue_and_log(target: @upload) do
      evaluator = Expenses::AiEvaluator.new(@upload)
      evaluator.evaluate

      @upload.update!(
        status: "evaluated",
        evaluated_at: Time.current
      )

      redirect_to expense_upload_path(@upload.slug), notice: "AI evaluation complete."
    end
  rescue StandardError => e
    redirect_to expense_upload_path(@upload.slug), alert: "Evaluation failed: #{e.message}"
  end

  private

  def set_upload
    @upload = ExpenseUpload.find_by(slug: params[:slug])
    return redirect_to expense_uploads_path, alert: "Upload not found" unless @upload
  end
end
