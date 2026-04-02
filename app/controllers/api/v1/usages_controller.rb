module Api
  module V1
    class UsagesController < BaseController
      def index
        usages = Usage.recent
        usages = usages.for_agent(params[:agent_slug]) if params[:agent_slug].present?
        result = paginate(usages)
        render_data(result[:records], meta: result[:meta])
      end

      def create
        usage = Usage.new(usage_params)
        rescue_and_log(target: usage) do
          usage.save!
          render_data(usage, status: :created)
        end
      rescue StandardError => e
        render_error(e.message)
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
