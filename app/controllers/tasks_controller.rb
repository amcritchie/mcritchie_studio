class TasksController < ApplicationController
  skip_before_action :require_authentication, only: [:index, :show]
  before_action :require_admin, except: [:index, :show]
  before_action :set_task, only: [:show, :edit, :update, :destroy, :queue, :start, :complete, :fail_task, :archive]

  def index
    tasks = Task.recent
    agent_filter = params[:agent_slug].presence || params[:agent].presence
    tasks = tasks.where(agent_slug: agent_filter) if agent_filter
    @tasks_by_stage = tasks.group_by(&:stage)
    @agents = Agent.order(:position)
  end

  def show
  end

  def new
    @task = Task.new
    @agents = Agent.active.order(:position)
  end

  def create
    @task = Task.new(task_params)
    rescue_and_log(target: @task) do
      @task.save!
      redirect_to task_path(@task.slug), notice: "Task created."
    end
  rescue StandardError => e
    @agents = Agent.active.order(:position)
    render :new, status: :unprocessable_entity
  end

  def edit
    @agents = Agent.active.order(:position)
  end

  def update
    rescue_and_log(target: @task) do
      @task.update!(task_params)
      redirect_to task_path(@task.slug), notice: "Task updated."
    end
  rescue StandardError => e
    @agents = Agent.active.order(:position)
    render :edit, status: :unprocessable_entity
  end

  def queue
    rescue_and_log(target: @task) do
      @task.queue!
      redirect_to task_path(@task.slug), notice: "Task queued."
    end
  rescue StandardError => e
    redirect_to task_path(@task.slug), alert: e.message
  end

  def start
    rescue_and_log(target: @task) do
      @task.start!
      redirect_to task_path(@task.slug), notice: "Task started."
    end
  rescue StandardError => e
    redirect_to task_path(@task.slug), alert: e.message
  end

  def complete
    rescue_and_log(target: @task) do
      @task.complete!
      redirect_to task_path(@task.slug), notice: "Task completed."
    end
  rescue StandardError => e
    redirect_to task_path(@task.slug), alert: e.message
  end

  def fail_task
    rescue_and_log(target: @task) do
      @task.fail!(params[:error_message])
      redirect_to task_path(@task.slug), notice: "Task marked as failed."
    end
  rescue StandardError => e
    redirect_to task_path(@task.slug), alert: e.message
  end

  def archive
    rescue_and_log(target: @task) do
      @task.archive!
      redirect_to task_path(@task.slug), notice: "Task archived."
    end
  rescue StandardError => e
    redirect_to task_path(@task.slug), alert: e.message
  end

  def destroy
    rescue_and_log(target: @task) do
      @task.destroy!
      redirect_to tasks_path, notice: "Task deleted."
    end
  rescue StandardError => e
    redirect_to tasks_path, alert: e.message
  end

  private

  def set_task
    @task = Task.find_by(slug: params[:slug])
    return redirect_to tasks_path, alert: "Task not found" unless @task
  end

  def task_params
    params.require(:task).permit(:title, :description, :priority, :agent_slug)
  end
end
