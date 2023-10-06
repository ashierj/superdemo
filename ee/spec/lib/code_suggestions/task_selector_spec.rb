# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::TaskSelector, feature_category: :code_suggestions do
  using RSpec::Parameterized::TableSyntax

  describe '.task' do
    let(:intent) { nil }
    let(:override_type) { false }
    let(:params) do
      {
        skip_generate_comment_prefix: skip_comment,
        current_file: { file_name: file_name, content_above_cursor: prefix },
        intent: intent
      }
    end

    subject { described_class.task(params: params) }

    shared_examples 'correct task detector' do
      context 'with the prefix, suffix produces the correct type' do
        where(:prefix, :type) do
          # rubocop:disable Layout/LineLength
          # Standard code generation comments
          "#{single_line_comment} #{generate_prefix}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment}#{generate_prefix}A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment

          # Line breaks at the end of the comment
          "#{single_line_comment} #{generate_prefix}A function that outputs the first 20 fibonacci numbers\n"  | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment}#{generate_prefix}A function that outputs the first 20 fibonacci numbers\n"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment} #{generate_prefix}define a calculator class that can be called from other functions \n \n\n" | CodeSuggestions::Tasks::CodeCompletion

          # These have characters _before_ the comment
          "end\n\n#{single_line_comment} #{generate_prefix}A function that outputs the first 20 fibonacci numbers"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "}\n\n\n\n#{single_line_comment} #{generate_prefix}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "    #{single_line_comment}#{generate_prefix}A function that outputs the first 20 fibonacci numbers"       | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "   \r\n   #{single_line_comment}#{generate_prefix}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment

          # These rely on case-insensitivity
          "#{single_line_comment} #{case_insensitive_prefixes[0]}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment} #{case_insensitive_prefixes[1]}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment}#{case_insensitive_prefixes[2]}A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment}#{case_insensitive_prefixes[3]}A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment

          # Multiline comments
          "#{single_line_comment} #{generate_prefix}A function that outputs\n#{single_line_comment} the first 20 fibonacci numbers\n" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment} #{generate_prefix}A function that outputs\n#{single_line_comment} the first 20 fibonacci numbers\n" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment}#{generate_prefix}A function that outputs\n#{single_line_comment}the first 20 fibonacci numbers\n"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment}#{generate_prefix}A function that outputs\n#{single_line_comment}the first 20 fibonacci numbers\n"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "#{single_line_comment}#{generate_prefix}A function that outputs fibonacci numbers\nconst hello = () => 'world';\n#{single_line_comment} first 20" | CodeSuggestions::Tasks::CodeCompletion

          # These are too short to be considered generation
          "#{single_line_comment} #{generate_prefix}A func" | CodeSuggestions::Tasks::CodeCompletion
          "#{single_line_comment} #{generate_prefix}A fun"  | CodeSuggestions::Tasks::CodeCompletion
          "#{single_line_comment}#{generate_prefix}A func"  | CodeSuggestions::Tasks::CodeCompletion
          "#{single_line_comment}#{generate_prefix}A fu"    | CodeSuggestions::Tasks::CodeCompletion

          # These include no comments at all
          'def fibonacci(i)'        | CodeSuggestions::Tasks::CodeCompletion
          'function fibonacci(x) {' | CodeSuggestions::Tasks::CodeCompletion
          # rubocop:enable Layout/LineLength
        end

        with_them do
          it { is_expected.to be_an_instance_of(override_type || type) }
        end
      end

      context 'when the last comment is a code generation' do
        let(:single_line_comment) { '#' }
        let(:prefix) do
          <<~TEXT
            # #{generate_prefix}A function that outputs the first 20 fibonacci numbers
            def fibonacci(x)

            # #{generate_prefix}A function that rounds every number to the nearest 10
          TEXT
        end

        let(:file_name) { 'test.py' }

        it 'only takes the last example in to account' do
          expect(subject).to be_an_instance_of(override_type || CodeSuggestions::Tasks::CodeGeneration::FromComment)
        end
      end

      context 'when the last comment is a code suggestion' do
        let(:single_line_comment) { '#' }
        let(:prefix) do
          <<~TEXT
            # #{generate_prefix}A function that outputs the first 20 fibonacci numbers

            def fibonacci(x)

          TEXT
        end

        let(:file_name) { 'test.py' }

        it 'only takes the last example in to account' do
          expect(subject).to be_an_instance_of(override_type || CodeSuggestions::Tasks::CodeCompletion)
        end
      end
    end

    context 'when content is a supported language' do
      CodeSuggestions::ProgrammingLanguage::LANGUAGE_COMMENT_FORMATS.each do |languages, format|
        lang = languages.first
        ext = CodeSuggestions::ProgrammingLanguage::SUPPORTED_LANGUAGES[lang].first
        single_comment_prefix = format[:single]

        # OCaml does not support single line comments
        context "for language #{lang} (#{single_comment_prefix}) without skip prefix", unless: lang == 'OCaml' do
          let(:skip_comment) { false }
          let(:generate_prefix) { 'GitLab Duo Generate: ' }
          let(:case_insensitive_prefixes) do
            [
              'GitLab duo generate: ',
              'gitLab Duo Generate: ',
              'gitLab Duo generate: ',
              'gitLab duo generate: '
            ]
          end

          let(:file_name) { "file.#{ext}" }
          let(:single_line_comment) do
            CodeSuggestions::ProgrammingLanguage.detect_from_filename(file_name).send(:comment_format)[:single]
          end

          it_behaves_like 'correct task detector'
        end

        # OCaml does not support single line comments
        context "for language #{lang} (#{single_comment_prefix}) with skip prefix", unless: lang == 'OCaml' do
          let(:skip_comment) { true }
          let(:generate_prefix) { '' }
          let(:case_insensitive_prefixes) { Array.new(4, '') }
          let(:file_name) { "file.#{ext}" }
          let(:single_line_comment) do
            CodeSuggestions::ProgrammingLanguage.detect_from_filename(file_name).send(:comment_format)[:single]
          end

          it_behaves_like 'correct task detector'
        end
      end
    end

    context 'with intent param' do
      let(:skip_comment) { false }

      context 'with the generation intent' do
        let(:intent) { 'generation' }
        let(:override_type) { CodeSuggestions::Tasks::CodeGeneration::FromComment }
        let(:generate_prefix) { '' }
        let(:case_insensitive_prefixes) { Array.new(4, '') }
        let(:file_name) { "file.py" }
        let(:single_line_comment) { "#" }

        it_behaves_like 'correct task detector'

        context 'when the instructions do not exist for generation' do
          let(:prefix) { "def fibonacci(i)" }

          it 'will still choose generation and set the prefix to the content' do
            result = subject
            expect(result).to be_an_instance_of(CodeSuggestions::Tasks::CodeGeneration::FromComment)

            expect(result.send(:params)[:prefix]).to eq(prefix)
          end
        end
      end

      context 'with the completion intent' do
        let(:intent) { 'completion' }
        let(:override_type) { CodeSuggestions::Tasks::CodeCompletion }
        let(:generate_prefix) { '' }
        let(:case_insensitive_prefixes) { Array.new(4, '') }
        let(:file_name) { "file.py" }
        let(:single_line_comment) { "#" }

        it_behaves_like 'correct task detector'
      end
    end

    context 'when prefix from result is empty' do
      let(:skip_comment) { false }
      let(:prefix) { 'prefix to set' }
      let(:intent) { 'generation' }
      let(:file_name) { "file.py" }

      it 'will set the content before cursor as prefix' do
        allow_next_instance_of(CodeSuggestions::InstructionsExtractor) do |instance|
          # The +'' is done to avoid `can't modify frozen String: ""` exception in tests
          allow(instance).to receive(:extract).and_return({ prefix: +'' })
        end

        result = subject

        expect(result.send(:params)[:prefix]).to eq(prefix)
      end
    end
  end
end
