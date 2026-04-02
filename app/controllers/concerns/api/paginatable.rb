module Api
  module Paginatable
    extend ActiveSupport::Concern

    private

    def paginate(scope)
      page = [params.fetch(:page, 1).to_i, 1].max
      per_page = [params.fetch(:per_page, 20).to_i, 100].min
      per_page = [per_page, 1].max

      total = scope.count
      records = scope.offset((page - 1) * per_page).limit(per_page)

      {
        records: records,
        meta: {
          page: page,
          per_page: per_page,
          total: total,
          total_pages: (total.to_f / per_page).ceil
        }
      }
    end
  end
end
