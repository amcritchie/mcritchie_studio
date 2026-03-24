module Api
  module V1
    class TasksController < BaseController
      def index
        tasks = Task.recent
        tasks = tasks.by_stage(params[:stage]) if params[:stage].present?
        tasks = tasks.where(agent_slug: params[:agent_slug]) if params[:agent_slug].present?
        render json: tasks
      end

      def show
        task = Task.find_by!(slug: params[:slug])
        render json: task
      end

      def create
        task = Task.create!(task_params)
        render json: task, status: :created
      end

      def update
        task = Task.find_by!(slug: params[:slug])
        task.update!(task_params)
        render json: task
      end

      def queue
        task = Task.find_by!(slug: params[:slug])
        task.queue!
        render json: task
      end

      def start
        task = Task.find_by!(slug: params[:slug])
        task.start!
        render json: task
      end

      def complete
        task = Task.find_by!(slug: params[:slug])
        task.complete!(params[:result] || {})
        render json: task
      end

      def fail_task
        task = Task.find_by!(slug: params[:slug])
        task.fail!(params[:error_message])
        render json: task
      end

      def archive
        task = Task.find_by!(slug: params[:slug])
        task.archive!
        render json: task
      end

      def destroy
        task = Task.find_by!(slug: params[:slug])
        task.destroy!
        head :no_content
      end

      private

      def task_params
        params.permit(:title, :description, :priority, :stage, :agent_slug, required_skills: [], metadata: {})
      end
    end
  end
end
