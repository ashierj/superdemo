# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe '.gitlab/ci/rules.gitlab-ci.yml', feature_category: :tooling do
  begin
    config = YAML.load_file(
      File.expand_path('../../.gitlab/ci/rules.gitlab-ci.yml', __dir__),
      aliases: true
    ).freeze
  rescue ArgumentError # Ruby 3.0 does not take `aliases: true`
    config = YAML.load_file(
      File.expand_path('../../.gitlab/ci/rules.gitlab-ci.yml', __dir__)
    ).freeze
  end

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
end
