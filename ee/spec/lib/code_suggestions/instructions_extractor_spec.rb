# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe CodeSuggestions::InstructionsExtractor, feature_category: :code_suggestions do
  describe '.extract' do
    let(:language) do
      CodeSuggestions::ProgrammingLanguage.from_language(CodeSuggestions::ProgrammingLanguage::DEFAULT)
    end

    subject { described_class.extract(language, content, first_line_regex) }

    context 'when content is nil' do
      let(:content) { nil }
      let(:first_line_regex) { CodeSuggestions::TaskSelector.first_comment_regex(language, nil, true) }

      it 'does not find instruction' do
        is_expected.to eq({})
      end
    end

    shared_examples_for 'detects comments correctly' do
      context 'when there is only one comment line' do
        let(:content) do
          <<~CODE
            #{comment_sign}Generate me a function
          CODE
        end

        specify do
          is_expected.to eq(
            prefix: "",
            instruction: "Generate me a function"
          )
        end
      end

      context 'when the comment is too short' do
        let(:content) do
          <<~CODE
            #{comment_sign}Generate
          CODE
        end

        it 'does not find instruction' do
          is_expected.to eq({})
        end
      end

      context 'when the last line is not a comment' do
        let(:content) do
          <<~CODE
            #{comment_sign}A function that outputs the first 20 fibonacci numbers

            def fibonacci(x)

          CODE
        end

        it 'does not find instruction' do
          is_expected.to eq({})
        end
      end

      context 'when there are some lines above the comment' do
        let(:content) do
          <<~CODE
            full_name()
            address()

            #{comment_sign}Generate me a function
          CODE
        end

        specify do
          is_expected.to eq(
            prefix: "full_name()\naddress()\n\n",
            instruction: "Generate me a function"
          )
        end
      end

      context 'when there are several comment in a row' do
        let(:content) do
          <<~CODE
            full_name()
            address()

            #{comment_sign}Generate me a function
            #{comment_sign}with 2 arguments
            #{comment_sign}first and last
          CODE
        end

        specify do
          is_expected.to eq(
            prefix: "full_name()\naddress()\n\n",
            instruction: "Generate me a function\nwith 2 arguments\nfirst and last"
          )
        end
      end

      context 'when there is another multiline comment above' do
        let(:content) do
          <<~CODE
            full_name()
            address()

            #{comment_sign}just some comment
            #{comment_sign}explaining something
            another_function()

            #{comment_sign}Generate me a function
            #{comment_sign}with 2 arguments
            #{comment_sign}first and last
          CODE
        end

        specify do
          expected_prefix = <<~CODE
            full_name()
            address()

            #{comment_sign}just some comment
            #{comment_sign}explaining something
            another_function()

          CODE

          is_expected.to eq(
            prefix: expected_prefix,
            instruction: "Generate me a function\nwith 2 arguments\nfirst and last"
          )
        end
      end

      context 'when the first line of multiline comment is do not met requirements' do
        let(:content) do
          <<~CODE
            full_name()
            address()

            #{comment_sign}just some comment
            #{comment_sign}explaining something
            another_function()

            #{comment_sign}Generate
            #{comment_sign}me a function
            #{comment_sign}with 2 arguments
            #{comment_sign}first and last
          CODE
        end

        it "does not find instruction" do
          is_expected.to eq({})
        end
      end

      context "with GitLab Duo Generate prefix" do
        let(:first_line_regex) { CodeSuggestions::TaskSelector.first_comment_regex(language, nil, false) }

        context 'when no prefix in the first line of the comment' do
          let(:content) do
            <<~CODE
              full_name()
              address()

              #{comment_sign}Generate me a function
              #{comment_sign}with 2 arguments
              #{comment_sign}first and last
            CODE
          end

          it 'does not find instruction' do
            is_expected.to eq({})
          end
        end

        context 'when there is a prefix in the first line of the comment' do
          let(:content) do
            <<~CODE
              full_name()
              address()

              #{comment_sign}GitLab Duo Generate: Generate me a function
              #{comment_sign}with 2 arguments
              #{comment_sign}first and last
            CODE
          end

          specify do
            is_expected.to eq(
              prefix: "full_name()\naddress()\n\n",
              instruction: "Generate me a function\nwith 2 arguments\nfirst and last"
            )
          end
        end

        context 'when comments are indented' do
          let(:content) do
            <<~CODE
              full_name()
              address()

                #{comment_sign}GitLab Duo Generate: Generate me a function
                #{comment_sign}with 2 arguments
                #{comment_sign}first and last
            CODE
          end

          specify do
            is_expected.to eq(
              prefix: "full_name()\naddress()\n\n",
              instruction: "Generate me a function\nwith 2 arguments\nfirst and last"
            )
          end
        end
      end
    end

    context 'when content is a supported language' do
      CodeSuggestions::ProgrammingLanguage::LANGUAGE_COMMENT_FORMATS.each do |languages, lang_format|
        languages.each do |lang|
          # OCaml does not support single line comments
          context "when using language #{lang}", unless: lang == 'OCaml' do
            let(:language) { CodeSuggestions::ProgrammingLanguage.from_language(lang) }
            let(:comment_sign) { lang_format[:single] }
            let(:first_line_regex) { CodeSuggestions::TaskSelector.first_comment_regex(language, nil, true) }

            it_behaves_like 'detects comments correctly'
          end
        end
      end

      context "when using alternate VBScript comment format" do
        let(:language) { CodeSuggestions::ProgrammingLanguage.from_language('VBScript') }
        let(:comment_sign) { 'REM' }
        let(:first_line_regex) { CodeSuggestions::TaskSelector.first_comment_regex(language, nil, true) }

        it_behaves_like 'detects comments correctly'
      end
    end
  end
end
