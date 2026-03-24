module Api
  module V1
    class UsagesController < BaseController
      def index
        usages = Usage.recent
        usages = usages.for_agent(params[:agent_slug]) if params[:agent_slug].present?
        render json: usages.limit(100)
      end

      def create
        usage = Usage.create!(usage_params)
        render json: usage, status: :created
      end

      private

      def usage_params
        params.permit(:agent_slug, :period_date, :period_type, :model,
                       :tokens_in, :tokens_out, :api_calls, :cost,
                       :tasks_completed, :tasks_failed, metadata: {})
      end
    end
  end
end
