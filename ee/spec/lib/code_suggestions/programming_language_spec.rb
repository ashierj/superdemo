# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe CodeSuggestions::ProgrammingLanguage, feature_category: :code_suggestions do
  describe '.comment_format' do
    subject { language.comment_format }

    described_class::LANGUAGE_COMMENT_FORMATS.each do |languages, format|
      languages.each do |lang|
        context "for the language #{lang}" do
          let(:language) { described_class.from_language(lang) }

          it { is_expected.to eq(format) }
        end
      end
    end

    context 'for unknown language' do
      let(:language) { described_class.from_language('unknown') }

      it { is_expected.to eq(described_class::DEFAULT_FORMAT) }
    end

    context 'for an unspecified language' do
      let(:language) { described_class.from_language('') }

      it { is_expected.to eq(described_class::DEFAULT_FORMAT) }
    end
  end

  describe '.detect_from_filename' do
    subject { described_class.detect_from_filename(file_name)&.name }

    described_class::SUPPORTED_LANGUAGES.each do |lang, exts|
      exts.each do |ext|
        context "for the file extension #{ext}" do
          let(:file_name) { "file.#{ext}" }

          it { is_expected.to eq(described_class.from_language(lang).name) }
        end
      end
    end

    context "for an unsupported language" do
      let(:file_name) { "file.nothing" }

      it { is_expected.to eq(described_class.from_language(described_class::DEFAULT).name) }
    end

    context "for no file extension" do
      let(:file_name) { "file" }

      it { is_expected.to eq(described_class.from_language(described_class::DEFAULT).name) }
    end

    context "for no file_name" do
      let(:file_name) { "" }

      it { is_expected.to eq(described_class.from_language(described_class::DEFAULT).name) }
    end
  end

  describe '.single_line_comment?' do
    subject { language.single_line_comment?(content) }

    described_class::LANGUAGE_COMMENT_FORMATS.each do |languages, _format|
      languages.each do |lang|
        context "for the language #{lang}", unless: lang == 'OCaml' do
          let(:language) { described_class.from_language(lang) }
          let(:single_line_comment_format) { language.comment_format[:single] }

          context "when it is a comment" do
            let(:content) { "#{single_line_comment_format} this is a comment " }

            it { is_expected.to be_truthy }
          end

          context "when it is not a comment" do
            let(:content) { "this is not a comment " }

            it { is_expected.to be_falsey }
          end

          context "when line doesn't start with comment" do
            let(:content) { "def something() { #{single_line_comment_format} this is a comment " }

            it { is_expected.to be_falsy }
          end

          context "when there is whitespace before the comment" do
            let(:content) { "      #{single_line_comment_format} this is a comment " }

            it { is_expected.to be_truthy }
          end
        end
      end
    end

    context "for the language OCaml" do
      let(:language) { described_class.from_language('OCaml') }

      context "when checking single line comment" do
        let(:content) { "// this is a comment " }

        it { is_expected.to be_falsey }
      end
    end

    context "for the alternate VBScript format" do
      let(:language) { described_class.from_language('VBScript') }

      context "when checking single line comment" do
        let(:content) { "REM this is a comment " }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.single_line_comment_format' do
    context 'when single_regexp is specified' do
      it 'will prefer regexp to string' do
        expect(described_class.from_language('VBScript').single_line_comment_format).to be_a(Regexp)
      end
    end
  end
end
