# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe '.gitlab/ci/rules.gitlab-ci.yml', feature_category: :tooling do
  config = YAML.safe_load_file(
    File.expand_path('../../.gitlab/ci/rules.gitlab-ci.yml', __dir__),
    aliases: true
  ).freeze

  context 'with changes' do
    config.each do |name, definition|
      next unless definition.is_a?(Hash) && definition['rules']

      definition['rules'].each do |rule|
        next unless rule.is_a?(Hash) && rule['changes']

        # See this for why we want to always have if
        # https://docs.gitlab.com/ee/development/pipelines/internals.html#avoid-force_gitlab_ci
        it "#{name} has corresponding if" do
          expect(rule).to include('if')
        end
      end
    end
  end

  describe 'start-as-if-foss' do
    let(:base_rules) { config.dig('.as-if-foss:rules:start-as-if-foss', 'rules') }

    context 'with .as-if-foss:rules:start-as-if-foss:allow-failure:manual' do
      let(:derived_rules) { config.dig('.as-if-foss:rules:start-as-if-foss:allow-failure:manual', 'rules') }

      it 'has the same rules as the base and also allow-failure and manual' do
        base_rules.zip(derived_rules).each do |(base, derived)|
          # !references should be the same. Stop rules should be the same.
          if base.is_a?(Array) || base['when'] == 'never'
            expect(base).to eq(derived)
          else
            expect(derived).to eq(
              base.merge('allow_failure' => true, 'when' => 'manual'))
          end
        end
      end
    end

    context 'with .as-if-foss:rules:start-as-if-foss:allow-failure' do
      let(:derived_rules) { config.dig('.as-if-foss:rules:start-as-if-foss:allow-failure', 'rules') }

      it 'has the same rules as the base and also allow-failure' do
        base_rules.zip(derived_rules).each do |(base, derived)|
          # !references should be the same. Stop rules should be the same.
          if base.is_a?(Array) || base['when'] == 'never'
            expect(base).to eq(derived)
          else
            expect(derived).to eq(base.merge('allow_failure' => true))
          end
        end
      end
    end
  end

  describe 'patterns' do
    foss_context = !Gitlab.ee?
    no_coverage_needed = (
      [
        ".editorconfig",
        ".foreman",
        ".git-blame-ignore-revs",
        ".gitlab/CODEOWNERS",
        ".gitleaksignore",
        ".license_encryption_key.pub",
        ".mailmap",
        ".prettierignore",
        ".projections.json.example",
        ".rubocop_revert_ignores.txt",
        ".ruby-version",
        ".test_license_encryption_key.pub",
        ".tool-versions",
        ".vale.ini",
        ".vscode/extensions.json",
        "Gemfile.checksum",
        "Guardfile",
        "INSTALLATION_TYPE",
        "LICENSE",
        "Pipfile.lock",
        "ee/LICENSE"
      ] +
      Dir.glob('.github/*', File::FNM_DOTMATCH) +
      Dir.glob('.gitlab/{issue,merge_request}_templates/**/*', File::FNM_DOTMATCH) +
      Dir.glob('.gitlab/*.toml', File::FNM_DOTMATCH) +
      Dir.glob('.lefthook/**/*', File::FNM_DOTMATCH) +
      Dir.glob('changelogs/*', File::FNM_DOTMATCH) +
      Dir.glob('file_hooks/**/*', File::FNM_DOTMATCH) +
      Dir.glob('patches/*', File::FNM_DOTMATCH) +
      Dir.glob('tmp/**/*', File::FNM_DOTMATCH) +
      Dir.glob('{,**/}.gitkeep', File::FNM_DOTMATCH) +
      Dir.glob('{,**/}.gitignore', File::FNM_DOTMATCH) +
      Dir.glob('*.md', File::FNM_DOTMATCH)
    ).freeze
    expected_missing_coverage = (
      Dir.glob("keeps/**/*") +
      Dir.glob("metrics_server/*") +
      Dir.glob("sidekiq_cluster/*") +
      ["\"workhorse/testdata/file-\\303\\244.pdf\""]
    ).freeze
    all_files = `git ls-files`.split("\n") - no_coverage_needed
    all_files -= Dir.glob('ee/**/*') if foss_context

    all_patterns_files = Set.new

    config.each do |name, patterns|
      next unless name.start_with?('.')
      next unless name.end_with?('patterns')
      # Ignore EE-only patterns list when in FOSS context
      next if foss_context && patterns.all? { |pattern| pattern =~ %r|{?ee/| }

      describe "patterns list `#{name}`" do
        patterns.each do |pattern|
          pattern_files = Dir.glob(pattern, File::FNM_DOTMATCH)
          all_patterns_files.merge(pattern_files)

          it "detects `#{pattern}` as a matching pattern" do
            matching_files = (all_files & pattern_files)

            expect(matching_files).not_to be_empty
          end
        end
      end
    end

    describe 'missed coverage', :aggregate_failures do
      it 'does not miss coverage' do
        missed_files = (all_files - all_patterns_files.to_a)
        missed_files_without_expected_missing_coverage = (missed_files - expected_missing_coverage)

        expect(missed_files).not_to be_empty
        expect(missed_files_without_expected_missing_coverage).to be_empty
        p(missed_files_without_expected_missing_coverage) unless missed_files_without_expected_missing_coverage.empty?
      end
    end
  end
end
