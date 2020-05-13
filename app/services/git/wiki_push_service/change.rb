# frozen_string_literal: true

module Git
  class WikiPushService
    class Change
      include Gitlab::Utils::StrongMemoize

      # @param [ProjectWiki] wiki
      # @param [Hash] change - must have keys `:oldrev` and `:newrev`
      # @param [Gitlab::Git::RawDiffChange] raw_change
      def initialize(project_wiki, change, raw_change)
        @wiki, @raw_change, @change = project_wiki, raw_change, change
      end

      def page
        strong_memoize(:page) { wiki.find_page(slug, revision) }
      end

      # See [Gitlab::Git::RawDiffChange#extract_operation] for the
      # definition of the full range of operation values.
      def event_action
        case raw_change.operation
        when :added
          Event::CREATED
        when :deleted
          Event::DESTROYED
        else
          Event::UPDATED
        end
      end

      def last_known_slug
        strip_extension(raw_change.old_path || raw_change.new_path)
      end

      private

      attr_reader :raw_change, :change, :wiki

      def filename
        return raw_change.old_path if deleted?

        raw_change.new_path
      end

      def slug
        strip_extension(filename)
      end

      def revision
        return change[:oldrev] if deleted?

        change[:newrev]
      end

      def deleted?
        raw_change.operation == :deleted
      end

      def strip_extension(filename)
        return unless filename

        File.basename(filename, File.extname(filename))
      end
    end
  end
end
