module Api
  module V1
    class ActivitiesController < BaseController
      def index
        activities = Activity.recent
        agent_filter = params[:agent_slug].presence || params[:agent].presence
        activities = activities.where(agent_slug: agent_filter) if agent_filter
        type_filter = params[:activity_type].presence || params[:type].presence
        activities = activities.by_type(type_filter) if type_filter
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
