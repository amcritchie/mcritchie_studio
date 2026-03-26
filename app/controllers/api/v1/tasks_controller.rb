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
        task = Task.new(task_params)
        rescue_and_log(target: task) do
          task.save!
          render json: task, status: :created
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def update
        task = Task.find_by!(slug: params[:slug])
        rescue_and_log(target: task) do
          task.update!(task_params)
          render json: task
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def queue
        task = Task.find_by!(slug: params[:slug])
        rescue_and_log(target: task) do
          task.queue!
          render json: task
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def start
        task = Task.find_by!(slug: params[:slug])
        rescue_and_log(target: task) do
          task.start!
          render json: task
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def complete
        task = Task.find_by!(slug: params[:slug])
        rescue_and_log(target: task) do
          task.complete!(params[:result] || {})
          render json: task
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def fail_task
        task = Task.find_by!(slug: params[:slug])
        rescue_and_log(target: task) do
          task.fail!(params[:error_message])
          render json: task
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def archive
        task = Task.find_by!(slug: params[:slug])
        rescue_and_log(target: task) do
          task.archive!
          render json: task
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        task = Task.find_by!(slug: params[:slug])
        rescue_and_log(target: task) do
          task.destroy!
          head :no_content
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def task_params
        params.permit(:title, :description, :priority, :agent_slug, required_skills: [], metadata: {})
      end
    end
  end
end
