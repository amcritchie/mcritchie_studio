class ExpenseTransactionsController < ApplicationController
  before_action :require_admin
  before_action :set_transaction, only: [:show, :update, :answer_review, :toggle_exclude]

  def index
    @transactions = ExpenseTransaction.includes(:expense_upload).recent

    # Filters
    @transactions = @transactions.where(status: params[:status]) if params[:status].present?
    @transactions = @transactions.by_category(params[:category]) if params[:category].present?
    @transactions = @transactions.by_account(params[:account]) if params[:account].present?
    @transactions = @transactions.by_card(params[:payment_method]) if params[:payment_method].present?
    @transactions = @transactions.by_month(params[:month]) if params[:month].present?
    if params[:q].present?
      @transactions = @transactions.where("raw_description ILIKE ? OR vendor ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    @per_page = 50
    @page = (params[:page] || 1).to_i
    @total_count = @transactions.count
    @transactions = @transactions.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
  end

  def update
    rescue_and_log(target: @transaction) do
      @transaction.update!(transaction_params.merge(manually_overridden: true, status: "classified"))
      redirect_to expense_transaction_path(@transaction.slug), notice: "Transaction updated."
    end
  rescue StandardError => e
    render :show, status: :unprocessable_entity
  end

  def answer_review
    rescue_and_log(target: @transaction) do
      @transaction.update!(user_answer: params[:user_answer])
      evaluator = Expenses::AiEvaluator.new(@transaction.expense_upload)
      evaluator.reclassify_with_answer(@transaction)
      redirect_to expense_transaction_path(@transaction.slug), notice: "Re-classified based on your answer."
    end
  rescue StandardError => e
    redirect_to expense_transaction_path(@transaction.slug), alert: "Review failed: #{e.message}"
  end

  def toggle_exclude
    rescue_and_log(target: @transaction) do
      @transaction.update!(excluded: !@transaction.excluded)
      redirect_back fallback_location: expense_transactions_path, notice: @transaction.excluded ? "Excluded." : "Included."
    end
  rescue StandardError => e
    redirect_back fallback_location: expense_transactions_path, alert: e.message
  end

  def export
    transactions = ExpenseTransaction.business_expenses.recent
    csv = Expenses::Exporter.new(transactions).to_csv
    send_data csv, filename: "business_expenses_#{Date.current}.csv", type: "text/csv"
  end

  def summary
    @business = ExpenseTransaction.business_expenses
    @needs_review = ExpenseTransaction.needs_review
    @total_business_cents = @business.sum(:amount_cents)

    @by_category = @business.group(:category).sum(:amount_cents).sort_by { |_, v| -v }
    @by_card = @business.group(:payment_method).sum(:amount_cents).sort_by { |_, v| -v }
    @by_account = @business.group(:account).sum(:amount_cents).sort_by { |_, v| -v }
    @by_month = @business.group("to_char(transaction_date, 'YYYY-MM')").sum(:amount_cents).sort_by { |k, _| k }
  end

  private

  def set_transaction
    @transaction = ExpenseTransaction.find_by(slug: params[:slug])
    return redirect_to expense_transactions_path, alert: "Transaction not found" unless @transaction
  end

  def transaction_params
    params.require(:expense_transaction).permit(:classification, :category, :deduction_type, :account, :vendor, :business_purpose)
  end
end
