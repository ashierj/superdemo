# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Navigation, feature_category: :global_search do
  describe '#tabs' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }

    let(:project_double) { instance_double(Project) }
    let(:group_double) { instance_double(Group) }
    let(:group) { nil }
    let(:options) { {} }
    let(:search_navigation) { described_class.new(user: user, project: project, group: group, options: options) }

    before do
      allow(search_navigation).to receive(:can?).and_return(true)
      allow(search_navigation).to receive(:tab_enabled_for_project?).and_return(false)
    end

    subject(:tabs) { search_navigation.tabs }

    context 'for epics tab' do
      where(:feature_flag, :project, :show_epics, :condition) do
        false | nil | false | false
        false | nil | nil | false
        false | ref(:project_double) | true | false
        false | ref(:project_double) | false | false
        false | ref(:project_double) | nil | false
        false | nil | true | false
        true | nil | false | false
        true | nil | nil | false
        true | ref(:project_double) | true | false
        true | ref(:project_double) | false | false
        true | ref(:project_double) | nil | false
        true | nil | true | true
      end

      with_them do
        let(:options) { { show_epics: show_epics } }

        it 'data item condition is set correctly' do
          stub_feature_flags(global_search_epics_tab: feature_flag)

          expect(tabs[:epics][:condition]).to eq(condition)
        end
      end
    end

    context 'for code tab' do
      context 'when project search' do
        let(:project) { project_double }
        let(:group) { nil }

        where(:tab_enabled_for_project, :condition) do
          true  | true
          false | false
        end

        with_them do
          before do
            allow(search_navigation).to receive(:tab_enabled_for_project?).and_return(tab_enabled_for_project)
          end

          it 'data item condition is set correctly' do
            expect(tabs[:blobs][:condition]).to eq(condition)
          end
        end
      end

      context 'when group search' do
        let(:project) { nil }
        let(:group) { group_double }

        where(:show_elasticsearch_tabs, :zoekt_enabled, :zoekt_enabled_for_group, :zoekt_enabled_for_user,
          :condition) do
          true  | false | false | false | true
          true  | true  | false | false | true
          false | false | false | false | false
          false | true  | false | false | false
          true  | false | true  | false | true
          true  | true  | true  | false | true
          false | false | true  | false | false
          false | true  | true  | false | false
          true  | false | false | true  | true
          true  | true  | false | true  | true
          false | false | false | true  | false
          false | true  | false | true  | false
          true  | false | true  | true  | true
          true  | true  | true  | true  | true
          false | false | true  | true  | false
          false | true  | true  | true  | true
        end

        with_them do
          before do
            allow(::Search::Zoekt).to receive(:search?).with(group).and_return(zoekt_enabled_for_group)
            allow(::Search::Zoekt).to receive(:enabled_for_user?).and_return(zoekt_enabled_for_user)
          end

          let(:options) { { show_elasticsearch_tabs: show_elasticsearch_tabs, zoekt_enabled: zoekt_enabled } }

          it 'data item condition is set correctly' do
            expect(tabs[:blobs][:condition]).to eq(condition)
          end
        end
      end

      context 'when global search' do
        let(:project) { nil }
        let(:group) { nil }

        where(:feature_flag, :show_elasticsearch_tabs, :zoekt_enabled, :condition) do
          false | false | false | false
          false | false | true | false
          true | true | false | true
          true | true | true | true
          true | false | false | false
          true | false | true | false
          true | false | true | false
          false | true | false | false
          false | true | true | false
        end

        with_them do
          let(:options) { { show_elasticsearch_tabs: show_elasticsearch_tabs, zoekt_enabled: zoekt_enabled } }

          before do
            stub_feature_flags(global_search_code_tab: feature_flag)
          end

          it 'data item condition is set correctly' do
            expect(tabs[:blobs][:condition]).to eq(condition)
          end
        end
      end
    end
  end
end
