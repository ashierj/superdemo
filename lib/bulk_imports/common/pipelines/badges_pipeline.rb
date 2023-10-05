# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class BadgesPipeline
        include Pipeline

        extractor BulkImports::Common::Extractors::RestExtractor,
          query: BulkImports::Common::Rest::GetBadgesQuery

        transformer Common::Transformers::ProhibitedAttributesTransformer

        def transform(context, data)
          return if data.blank?
          # Project badges API returns badges of both group and project kind. To avoid creation of duplicates for the group we skip group badges when it's a project.
          return if context.entity.project? && group_badge?(data)

          {
            name: data['name'],
            link_url: data['link_url'],
            image_url: data['image_url']
          }
        end

        def load(context, data)
          return if data.blank?

          if context.entity.project?
            context.portable.project_badges.create!(data)
          else
            context.portable.badges.create!(data)
          end
        end

        def already_processed?(data, _)
          values = Gitlab::Cache::Import::Caching.values_from_set(cache_key)
          values.include?(OpenSSL::Digest::SHA256.hexdigest(data.to_s))
        end

        def save_processed_entry(data, _)
          Gitlab::Cache::Import::Caching.set_add(cache_key, OpenSSL::Digest::SHA256.hexdigest(data.to_s))
        end

        private

        def group_badge?(data)
          data['kind'] == 'group'
        end
      end
    end
  end
end
