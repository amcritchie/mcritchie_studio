module Api
  module V1
    class ActivitiesController < BaseController
      def index
        activities = Activity.recent
        activities = activities.where(agent_slug: params[:agent_slug]) if params[:agent_slug].present?
        activities = activities.by_type(params[:activity_type]) if params[:activity_type].present?
        render json: activities.limit(100)
      end

      def create
        activity = Activity.new(activity_params)
        rescue_and_log(target: activity) do
          activity.save!
          render json: activity, status: :created
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def activity_params
        params.permit(:agent_slug, :activity_type, :description, :task_slug, metadata: {})
      end
    end
  end
end
