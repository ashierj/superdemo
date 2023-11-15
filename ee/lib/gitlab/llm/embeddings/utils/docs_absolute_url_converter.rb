# frozen_string_literal: true

module Gitlab
  module Llm
    module Embeddings
      module Utils
        class DocsAbsoluteUrlConverter
          def self.convert(content, base_url)
            return unless content

            html = Banzai.render(content, { base_url: base_url, pipeline: :duo_chat_documentation })
            return unless html

            Gitlab::Email::HtmlToMarkdownParser.convert(html)
          end
        end
      end
    end
  end
end
