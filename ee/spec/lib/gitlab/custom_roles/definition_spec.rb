# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CustomRoles::Definition, feature_category: :permissions do
  let_it_be(:read_vuln_attr) do
    {
      name: 'read_vulnerability',
      description: 'Allows read access to the vulnerability reports.',
      introduced_by_issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/1',
      introduced_by_mr: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1',
      feature_category: 'vulnerability_management',
      milestone: '16.0',
      group_ability: true,
      project_ability: true
    }
  end

  let_it_be(:admin_vuln_attr) do
    {
      name: 'admin_vulnerability',
      description: 'Allows admin access to the vulnerability reports.',
      introduced_by_issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/2',
      introduced_by_mr: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/2',
      feature_category: 'vulnerability_management',
      milestone: '16.1',
      group_ability: true,
      project_ability: true,
      requirement: 'read_vulnerability'
    }
  end

  describe '.all' do
    let_it_be(:store) { Dir.mktmpdir('path1') }
    let_it_be(:yaml_read_vuln) { read_vuln_attr.deep_stringify_keys.to_yaml }
    let_it_be(:yaml_admin_vuln) { admin_vuln_attr.deep_stringify_keys.to_yaml }

    subject(:abilities) { described_class.all }

    context 'when initialized' do
      let_it_be(:yaml_path) { Rails.root.join("ee/config/custom_abilities/*.yml") }

      let_it_be(:defined_abilities) do
        Dir.glob(yaml_path).map do |file|
          File.basename(file, '.yml').to_sym
        end
      end

      it 'does not reload the abilities from the yaml files' do
        expect(described_class).not_to receive(:load_abilities!)

        abilities
      end

      it 'returns the defined abilities' do
        expect(abilities.keys).to match_array(defined_abilities)
      end
    end

    context 'when not initialized' do
      before do
        described_class.definitions = nil

        allow(described_class).to receive(:path).and_return(File.join(store, '**', '*.yml'))
      end

      after(:all) do
        FileUtils.rm_rf(store)
      end

      it 'reloads the abilities from the yaml files' do
        expect(described_class).to receive(:load_abilities!)

        abilities
      end

      context 'when there are no custom abilities' do
        it 'an empty hash is returned' do
          expect(abilities).to eq({})
        end
      end

      context 'when there are some custom abilities' do
        it 'correct hash is returned' do
          write_permission(yaml_read_vuln, store, 'read_vulnerability')
          write_permission(yaml_admin_vuln, store, 'admin_vulnerability')

          expect(abilities).to eq(
            {
              read_vulnerability: read_vuln_attr,
              admin_vulnerability: admin_vuln_attr
            }
          )
        end
      end
    end

    def write_permission(content, store, ability)
      file_name = File.join('custom_abilities', "#{ability}.yml")
      path = File.join(store, file_name)
      dir = File.dirname(path)

      FileUtils.mkdir_p(dir)
      File.write(path, content)
    end
  end
end
