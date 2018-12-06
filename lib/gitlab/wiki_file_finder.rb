# frozen_string_literal: true

module Gitlab
  class WikiFileFinder < FileFinder
    BATCH_SIZE = 100

    attr_reader :repository

    def initialize(project, ref)
      @project = project
      @ref = ref
      @repository = project.wiki.repository
    end

    private

    def search_filenames(query)
      safe_query = Regexp.escape(query.tr(' ', '-'))
      safe_query = Regexp.new(safe_query, Regexp::IGNORECASE)
      filenames = repository.ls_files(ref)

      filenames.grep(safe_query).first(BATCH_SIZE)
    end
  end
end
