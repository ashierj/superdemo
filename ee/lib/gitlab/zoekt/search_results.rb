# frozen_string_literal: true

module Gitlab
  module Zoekt
    class SearchResults
      include ActionView::Helpers::NumberHelper
      include Gitlab::Utils::StrongMemoize

      ZOEKT_COUNT_LIMIT = 5_000
      DEFAULT_PER_PAGE = Gitlab::SearchResults::DEFAULT_PER_PAGE

      attr_reader :current_user, :query, :public_and_internal_projects, :order_by, :sort, :filters, :error

      # Limit search results by passed projects
      # It allows us to search only for projects user has access to
      attr_reader :limit_project_ids, :node_id

      def initialize(current_user, query, limit_project_ids = nil, node_id:, order_by: nil, sort: nil, filters: {})
        @current_user = current_user
        @query = query
        @limit_project_ids = limit_project_ids
        @node_id = node_id
        @order_by = order_by
        @sort = sort
        @filters = filters
      end

      def objects(_scope, page: 1, per_page: DEFAULT_PER_PAGE, preload_method: nil)
        blobs(page: page, per_page: per_page, preload_method: preload_method)
      end

      def formatted_count(_scope)
        limited_counter_with_delimiter(blobs_count)
      end

      def blobs_count
        @blobs_count ||= blobs.total_count
      end

      # These aliases act as an adapter to the Gitlab::SearchResults
      # interface, which is mostly implemented by this class.
      alias_method :limited_blobs_count, :blobs_count

      def parse_zoekt_search_result(result, project)
        ref = project.default_branch_or_main
        path = result[:path]
        basename = File.join(File.dirname(path), File.basename(path, '.*'))
        content = result[:content]
        project_id = project.id

        ::Gitlab::Search::FoundBlob.new(
          path: path,
          basename: basename,
          ref: ref,
          startline: [result[:line] - 1, 0].max,
          highlight_line: result[:line],
          data: content,
          project: project,
          project_id: project_id
        )
      end

      def aggregations(_scope)
        []
      end

      def highlight_map(_)
        nil
      end

      def failed?
        error.present?
      end

      private

      def base_options
        {
          current_user: current_user,
          project_ids: limit_project_ids,
          public_and_internal_projects: public_and_internal_projects,
          order_by: order_by,
          sort: sort,
          node_id: node_id
        }
      end

      def memoize_key(scope, page:, per_page:, count_only:)
        count_only ? "#{scope}_results_count".to_sym : "#{scope}_#{page}_#{per_page}"
      end

      def blobs(page: 1, per_page: DEFAULT_PER_PAGE, count_only: false, preload_method: nil)
        return Kaminari.paginate_array([]) if query.blank?

        strong_memoize(memoize_key(:blobs, page: page, per_page: per_page, count_only: count_only)) do
          search_as_found_blob(
            query,
            Repository,
            page: (page || 1).to_i,
            per_page: per_page,
            options: base_options.merge(count_only: count_only).merge(filters.slice(:language)),
            preload_method: preload_method
          )
        end
      end

      def limited_counter_with_delimiter(count)
        if count.nil?
          number_with_delimiter(0)
        elsif count >= ZOEKT_COUNT_LIMIT
          "#{number_with_delimiter(ZOEKT_COUNT_LIMIT)}+"
        else
          number_with_delimiter(count)
        end
      end

      def search_as_found_blob(query, _repositories, page:, per_page:, options:, preload_method:)
        zoekt_search_and_wrap(query, page: page,
          per_page: per_page,
          options: options,
          preload_method: preload_method) do |result, project|
          parse_zoekt_search_result(result, project)
        end
      end

      # Performs zoekt search and parses the response
      #
      # @param query [String] search query
      # @param per_page [Integer] how many documents per page
      # @param options [Hash] additional options
      # @param page_limit [Integer] maximum number of pages we parse
      # @return [Array<Hash, Integer>] the results and total count
      def zoekt_search(query, per_page:, options:, page_limit:)
        response = ::Gitlab::Search::Zoekt::Client.search(
          query,
          num: ZOEKT_COUNT_LIMIT,
          project_ids: options[:project_ids],
          node_id: options[:node_id]
        )

        if response[:Error]
          @blobs_count = 0
          @error = response[:Error]
          return [{}, 0]
        end

        total_count = response[:Result][:MatchCount].clamp(0, ZOEKT_COUNT_LIMIT)
        results = zoekt_extract_result_pages(response, per_page: per_page, page_limit: page_limit)

        [results, total_count]
      end

      # Extracts results from the Zoekt response
      #
      # @param response [Hash] JSON response converted to hash
      # @param per_page [Integer] how many documents per page
      # @param page_limit [Integer] maximum number of pages we parse
      # @return [Hash<Integer, Array<Hash>>] results hash with pages as keys (zero-based)
      def zoekt_extract_result_pages(response, per_page:, page_limit:)
        results = {}
        i = 0

        files = response.dig(:Result, :Files) || []
        files.each do |file|
          project_id = file[:Repository].to_i

          file[:LineMatches].each do |match|
            current_page = i / per_page
            return results if current_page == page_limit

            results[current_page] ||= []
            results[current_page] << {
              project_id: project_id,
              content: [match[:Before], match[:Line], match[:After]].compact.map { |l| Base64.decode64(l) }.join("\n"),
              line: match[:LineNumber],
              path: file[:FileName]
            }

            i += 1
          end
        end

        results
      end

      def zoekt_search_and_wrap(query, per_page:, page: 1, options: {}, preload_method: nil, &blk)
        zoekt_cache = ::Search::Zoekt::Cache.new(
          query,
          current_user: current_user,
          page: page,
          per_page: per_page,
          project_ids: options[:project_ids],
          max_per_page: DEFAULT_PER_PAGE * 2
        )

        search_results, total_count = zoekt_cache.fetch do |page_limit|
          zoekt_search(query, per_page: per_page, page_limit: page_limit, options: options)
        end

        items, total_count = yield_each_zoekt_search_result(
          search_results[page - 1],
          preload_method,
          total_count,
          &blk
        )

        offset = (page - 1) * per_page
        Kaminari.paginate_array(items, total_count: total_count, limit: per_page, offset: offset)
      end

      def yield_each_zoekt_search_result(response, preload_method, total_count)
        return [[], total_count] if total_count == 0 || response.blank?

        project_ids = response.pluck(:project_id).uniq # rubocop:disable CodeReuse/ActiveRecord
        projects = Project.with_route.id_in(project_ids)
        projects = projects.public_send(preload_method) if preload_method # rubocop:disable GitlabSecurity/PublicSend
        projects = projects.index_by(&:id)

        items = response.map do |result|
          project_id = result[:project_id]
          project = projects[project_id]

          if project.nil? || project.pending_delete?
            total_count -= 1
            next
          end

          yield(result, project)
        end

        # Remove results for deleted projects
        items.compact!

        [items, total_count]
      end
    end
  end
end
