class TasksController < ApplicationController
  skip_before_action :require_authentication, only: [:index, :show]
  before_action :set_task, only: [:show, :edit, :update, :destroy, :queue, :start, :complete, :fail_task, :archive]

  def index
    tasks = Task.recent
    tasks = tasks.where(agent_slug: params[:agent]) if params[:agent].present?
    @tasks_by_stage = tasks.group_by(&:stage)
    @agents = Agent.order(:name)
  end

  def show
  end

  def new
    @task = Task.new
    @agents = Agent.active.order(:name)
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to task_path(@task.slug), notice: "Task created."
    else
      @agents = Agent.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @agents = Agent.active.order(:name)
  end

  def update
    if @task.update(task_params)
      redirect_to task_path(@task.slug), notice: "Task updated."
    else
      @agents = Agent.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def queue
    @task.queue!
    redirect_to task_path(@task.slug), notice: "Task queued."
  end

  def start
    @task.start!
    redirect_to task_path(@task.slug), notice: "Task started."
  end

  def complete
    @task.complete!
    redirect_to task_path(@task.slug), notice: "Task completed."
  end

  def fail_task
    @task.fail!(params[:error_message])
    redirect_to task_path(@task.slug), notice: "Task marked as failed."
  end

  def archive
    @task.archive!
    redirect_to task_path(@task.slug), notice: "Task archived."
  end

  def destroy
    @task.destroy!
    redirect_to tasks_path, notice: "Task deleted."
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
