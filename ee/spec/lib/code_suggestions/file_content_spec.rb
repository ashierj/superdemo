# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::FileContent, feature_category: :code_suggestions do
  describe '#quite_small?' do
    subject { described_class.new(language, content_above_cursor, content_below_cursor) }

    let(:language) do
      CodeSuggestions::ProgrammingLanguage.new('Ruby')
    end

    let(:content_above_cursor) { '' }
    let(:content_below_cursor) { '' }

    context 'when content above cursor is blank' do
      let(:content_above_cursor) { '' }

      it { is_expected.to be_quite_small }
    end

    context 'when content above cursor is nil' do
      let(:content_above_cursor) { nil }

      it { is_expected.to be_quite_small }
    end

    context 'when file content above cursor is less than 5 lines' do
      let(:content_above_cursor) do
        <<~CODE
          # A function that outputs the first 20 fibonacci numbers

          def fibonacci(x)

        CODE
      end

      it { is_expected.to be_quite_small }

      context 'when file content below cursor more than 5 lines' do
        let(:content_below_cursor) do
          <<~CODE
            end

            # Method to calculate the square root of a number
            def square_root(number)
              if number < 0
                raise ArgumentError, "Square root of a negative number is undefined"
              else
                Math.sqrt(number)
              end
            end
          CODE
        end

        it { is_expected.not_to be_quite_small }
      end

      context 'when file content below is less than 5 lines' do
        let(:content_below_cursor) do
          <<~CODE
            end

            def square_root(number)
            end
          CODE
        end

        it { is_expected.to be_quite_small }
      end
    end

    context 'when content above cursor is 5 or more lines' do
      let(:content_above_cursor) do
        <<~CODE
          # frozen_string_literal: true

          module CodeSuggestions
            class FileContent
              MIN_LINES_OF_CODE = 5

              def initialize(language, content_above_cursor, content_below_cursor = '')
                @language = language
                @content_above_cursor = content_above_cursor
                @content_below_cursor = content_below_cursor
              end

              attr_reader :language, :content_above_cursor, :content_below_cursor

              # Generate me a function
              # with 2 arguments
              # first and last
        CODE
      end

      it { is_expected.not_to be_quite_small }
    end
  end
end
