# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Zoekt::SearchResults, :zoekt, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:project_1) { create(:project, :public, :repository) }
  let_it_be(:project_2) { create(:project, :public, :repository) }

  let(:query) { 'hello world' }
  let(:limit_projects) { Project.id_in(project_1.id) }
  let(:node_id) { ::Search::Zoekt::Node.last.id }

  before do
    zoekt_ensure_project_indexed!(project_1)
    zoekt_ensure_project_indexed!(project_2)
  end

  describe 'blobs' do
    before do
      zoekt_ensure_project_indexed!(project_1)
    end

    it 'finds blobs by regex search' do
      results = described_class.new(user, 'use.*egex', limit_projects, node_id: node_id)
      blobs = results.objects('blobs')

      expect(blobs.map(&:data).join).to include("def username_regex\n      default_regex")
      expect(results.blobs_count).to eq 5
    end

    it 'instantiates zoekt cache with correct arguments' do
      query = 'use.*egex'
      results = described_class.new(user, query, limit_projects, node_id: node_id, filters: { include_archived: true })

      expect(Search::Zoekt::Cache).to receive(:new).with(
        query,
        current_user: user,
        page: 1,
        per_page: described_class::DEFAULT_PER_PAGE,
        project_ids: [project_1.id],
        max_per_page: described_class::DEFAULT_PER_PAGE * 2,
        search_mode: :exact
      ).and_call_original

      results.objects('blobs')
    end

    it 'correctly handles pagination' do
      per_page = 2

      results = described_class.new(user, 'use.*egex', limit_projects, node_id: node_id)
      blobs_page1 = results.objects('blobs', page: 1, per_page: per_page)
      blobs_page2 = results.objects('blobs', page: 2, per_page: per_page)
      blobs_page3 = results.objects('blobs', page: 3, per_page: per_page)

      expect(blobs_page1.map(&:data).join).to include("def username_regex\n      default_regex")
      expect(blobs_page2.map(&:data).join).to include("regexp group matches\n  (`$1`, `$2`, etc)")
      expect(blobs_page3.map(&:data).join).to include("more readable and you\n  can add some useful comments")
      expect(results.blobs_count).to eq 5
    end

    it 'returns empty result when request is out of page range' do
      results = described_class.new(user, 'use.*egex', limit_projects, node_id: node_id)
      blobs_page = results.objects('blobs', page: 256, per_page: 2)

      expect(blobs_page).to be_empty
    end

    it 'limits to the zoekt count limit' do
      stub_const("#{described_class}::ZOEKT_COUNT_LIMIT", 2)

      results = described_class.new(user, 'test', limit_projects, node_id: node_id)
      expect(results.blobs_count).to eq 2
    end

    it 'finds blobs from searched projects only' do
      project_3 = create :project, :repository, :private
      zoekt_ensure_project_indexed!(project_3)
      project_3.add_reporter(user)

      projects = Project.id_in([project_1.id, project_3.id])
      results = described_class.new(user, 'project_name_regex', limit_projects, node_id: node_id)
      expect(results.blobs_count).to eq 1
      result_project_ids = results.objects('blobs').map(&:project_id)
      expect(result_project_ids.uniq).to match_array([project_1.id])

      results = described_class.new(user, 'project_name_regex', projects, node_id: node_id)
      result_project_ids = results.objects('blobs').map(&:project_id)
      expect(result_project_ids.uniq).to match_array([project_1.id, project_3.id])
      expect(results.blobs_count).to eq 2
    end

    it 'raises an exception when limit_project_ids is passed as :any' do
      expect do
        described_class.new(user, 'project_name_regex', :any, node_id: node_id).objects('blobs')
      end.to raise_error('Global search is not supported')
    end

    it 'returns zero when blobs are not found' do
      results = described_class.new(user, 'asdfg', limit_projects, node_id: node_id)

      expect(results.blobs_count).to eq 0
    end

    using RSpec::Parameterized::TableSyntax

    where(:param_regex_mode, :feature_flag_zoekt_exact_search, :search_mode_sent_to_client) do
      nil     | true  | :exact
      true    | true  | :regex
      false   | true  | :exact
      'true'  | true  | :regex
      'false' | true  | :exact
      nil     | false | :regex
      true    | false | :regex
      false   | false | :regex
      'true'  | false | :regex
      'false' | false | :regex
    end

    with_them do
      it 'calls search on Gitlab::Search::Zoekt::Client with correct parameters' do
        stub_feature_flags(zoekt_exact_search: feature_flag_zoekt_exact_search)

        expect(Gitlab::Search::Zoekt::Client).to receive(:search).with(
          query,
          num: described_class::ZOEKT_COUNT_LIMIT,
          project_ids: [project_1.id],
          node_id: node_id,
          search_mode: search_mode_sent_to_client
        ).and_call_original

        described_class.new(user, query, limit_projects, node_id: node_id,
          modes: { regex: param_regex_mode }).objects('blobs')
      end
    end

    context 'when modes is not passed' do
      context 'and feature flag zoekt_exact_search is disabled' do
        before do
          stub_feature_flags(zoekt_exact_search: false)
        end

        it 'calls search on Gitlab::Search::Zoekt::Client with correct parameters' do
          expect(Gitlab::Search::Zoekt::Client).to receive(:search).with(
            query,
            num: described_class::ZOEKT_COUNT_LIMIT,
            project_ids: [project_1.id],
            node_id: node_id,
            search_mode: :regex
          ).and_call_original
          described_class.new(user, query, limit_projects, node_id: node_id).objects('blobs')
        end
      end

      it 'calls search on Gitlab::Search::Zoekt::Client with correct parameters' do
        expect(Gitlab::Search::Zoekt::Client).to receive(:search).with(
          query,
          num: described_class::ZOEKT_COUNT_LIMIT,
          project_ids: [project_1.id],
          node_id: node_id,
          search_mode: :exact
        ).and_call_original
        described_class.new(user, query, limit_projects, node_id: node_id).objects('blobs')
      end
    end

    it 'calls search on Gitlab::Search::Zoekt::Client with correct parameters' do
      expect(Gitlab::Search::Zoekt::Client).to receive(:search).with(
        query,
        num: described_class::ZOEKT_COUNT_LIMIT,
        project_ids: [project_1.id],
        node_id: node_id,
        search_mode: :exact
      ).and_call_original
      described_class.new(user, query, limit_projects, node_id: node_id).objects('blobs')
    end

    it 'returns zero when error is raised by client' do
      client_error = ::Search::Zoekt::Errors::ClientConnectionError.new('test')
      allow(::Gitlab::Search::Zoekt::Client).to receive(:search).and_raise(client_error)

      results = described_class.new(user, 'test', limit_projects, node_id: node_id)

      expect(results.blobs_count).to eq 0
      expect(results.error).to eq(client_error.message)
    end

    it 'returns zero when a node backoff occurs' do
      client_error = ::Search::Zoekt::Errors::BackoffError.new('test')
      allow(::Gitlab::Search::Zoekt::Client).to receive(:search).and_raise(client_error)

      results = described_class.new(user, 'test', limit_projects, node_id: node_id)

      expect(results.blobs_count).to eq 0
      expect(results.error).to eq(client_error.message)
    end

    context 'when searching with special characters', :aggregate_failures do
      let(:examples) do
        {
          'perlMethodCall' => '$my_perl_object->perlMethodCall',
          '"absolute_with_specials.txt"' => '/a/longer/file-path/absolute_with_specials.txt',
          '"components-within-slashes"' => '/file-path/components-within-slashes/',
          'bar\(x\)' => 'Foo.bar(x)',
          'someSingleColonMethodCall' => 'LanguageWithSingleColon:someSingleColonMethodCall',
          'javaLangStaticMethodCall' => 'MyJavaClass::javaLangStaticMethodCall',
          'tokenAfterParentheses' => 'ParenthesesBetweenTokens)tokenAfterParentheses',
          'ruby_call_method_123' => 'RubyClassInvoking.ruby_call_method_123(with_arg)',
          'ruby_method_call' => 'RubyClassInvoking.ruby_method_call(with_arg)',
          '#ambitious-planning' => 'We [plan ambitiously](#ambitious-planning).',
          'ambitious-planning' => 'We [plan ambitiously](#ambitious-planning).',
          'tokenAfterCommaWithNoSpace' => 'WouldHappenInManyLanguages,tokenAfterCommaWithNoSpace',
          'missing_token_around_equals' => 'a.b.c=missing_token_around_equals',
          'and;colons:too\$' => 'and;colons:too$',
          '"differeñt-lønguage.txt"' => 'another/file-path/differeñt-lønguage.txt',
          '"relative-with-specials.txt"' => 'another/file-path/relative-with-specials.txt',
          'ruby_method_123' => 'def self.ruby_method_123(ruby_another_method_arg)',
          'ruby_method_name' => 'def self.ruby_method_name(ruby_method_arg)',
          '"dots.also.neeeeed.testing"' => 'dots.also.neeeeed.testing',
          '.testing' => 'dots.also.neeeeed.testing',
          'dots' => 'dots.also.neeeeed.testing',
          'also.neeeeed' => 'dots.also.neeeeed.testing',
          'neeeeed' => 'dots.also.neeeeed.testing',
          'tests-image' => 'extends: .gitlab-tests-image',
          'gitlab-tests' => 'extends: .gitlab-tests-image',
          'gitlab-tests-image' => 'extends: .gitlab-tests-image',
          'foo/bar' => 'https://s3.amazonaws.com/foo/bar/baz.png',
          'https://test.or.dev.com/repository' => 'https://test.or.dev.com/repository/maven-all',
          'test.or.dev.com/repository/maven-all' => 'https://test.or.dev.com/repository/maven-all',
          'repository/maven-all' => 'https://test.or.dev.com/repository/maven-all',
          'https://test.or.dev.com/repository/maven-all' => 'https://test.or.dev.com/repository/maven-all',
          'bar-baz-conventions' => 'id("foo.bar-baz-conventions")',
          'baz-conventions' => 'id("foo.bar-baz-conventions")',
          'baz' => 'id("foo.bar-baz-conventions")',
          'bikes-3.4' => 'include "bikes-3.4"',
          'sql_log_bin' => 'q = "SET @@session.sql_log_bin=0;"',
          'sql_log_bin=0' => 'q = "SET @@session.sql_log_bin=0;"',
          'v3/delData' => 'uri: "v3/delData"',
          '"us-east-2"' => 'us-east-2'
        }
      end

      before do
        examples.values.uniq.each do |file_content|
          file_name = Digest::SHA256.hexdigest(file_content)
          project_1.repository.create_file(user, file_name, file_content, message: 'Some commit message',
            branch_name: 'master')
        end

        zoekt_ensure_project_indexed!(project_1)
      end

      it 'finds all examples' do
        examples.each do |search_term, file_content|
          file_name = Digest::SHA256.hexdigest(file_content)
          search_results_instance = described_class.new(user, search_term, limit_projects, node_id: node_id,
            modes: { regex: true })
          results = search_results_instance.objects('blobs').map(&:path)
          expect(results).to include(file_name)
        end
      end
    end

    describe 'filtering' do
      include ProjectForksHelper

      let_it_be(:archived_project) { create(:project, :public, :archived, :repository) }
      let!(:forked_project) { fork_project(project_1) }
      let(:all_project_ids) { limit_projects.pluck_primary_key }
      let(:non_archived_project_ids) { all_project_ids - [archived_project.id] }
      let(:non_forked_project_ids) { all_project_ids - [forked_project.id] }
      let(:filters) { {} }

      subject(:search) do
        described_class.new(user, query, limit_projects, node_id: node_id, filters: filters).objects('blobs')
      end

      shared_examples 'a non-filtered search' do
        it 'calls search on Gitlab::Search::Zoekt::Client with all project ids' do
          expect(Gitlab::Search::Zoekt::Client).to receive(:search).with(
            query,
            num: described_class::ZOEKT_COUNT_LIMIT,
            project_ids: non_archived_project_ids,
            node_id: node_id,
            search_mode: :exact
          ).and_call_original

          search
        end
      end

      context 'when no filters are passed' do
        it 'calls search on Gitlab::Search::Zoekt::Client with non archived project ids' do
          expect(Gitlab::Search::Zoekt::Client).to receive(:search).with(
            query,
            num: described_class::ZOEKT_COUNT_LIMIT,
            project_ids: non_archived_project_ids,
            node_id: node_id,
            search_mode: :exact
          ).and_call_original

          search
        end

        context 'when search_add_archived_filter_to_zoekt flag is disabled' do
          before do
            stub_feature_flags(search_add_archived_filter_to_zoekt: false)
          end

          it_behaves_like 'a non-filtered search'
        end
      end

      describe 'archive filters' do
        context 'when include_archived filter is set to true' do
          let(:filters) { { include_archived: true } }

          it_behaves_like 'a non-filtered search'

          context 'when search_add_archived_filter_to_zoekt flag is disabled' do
            before do
              stub_feature_flags(search_add_archived_filter_to_zoekt: false)
            end

            it_behaves_like 'a non-filtered search'
          end
        end

        context 'when include_archived filter is set to false' do
          let(:filters) { { include_archived: false } }

          it 'calls search on Gitlab::Search::Zoekt::Client with non archived project ids' do
            expect(Gitlab::Search::Zoekt::Client).to receive(:search).with(
              query,
              num: described_class::ZOEKT_COUNT_LIMIT,
              project_ids: non_archived_project_ids,
              node_id: node_id,
              search_mode: :exact
            ).and_call_original

            search
          end

          context 'and all projects are archived' do
            let(:limit_projects) { ::Project.archived }

            it 'returns an empty result set' do
              expect(Gitlab::Search::Zoekt::Client).not_to receive(:search)

              expect(search).to be_empty
            end
          end

          context 'when search_add_archived_filter_to_zoekt flag is disabled' do
            before do
              stub_feature_flags(search_add_archived_filter_to_zoekt: false)
            end

            it_behaves_like 'a non-filtered search'
          end
        end
      end

      describe 'fork filters' do
        context 'when include_forked filter is set to true' do
          let(:filters) { { include_forked: true } }

          it_behaves_like 'a non-filtered search'

          context 'when search_add_fork_filter_to_zoekt flag is disabled' do
            before do
              stub_feature_flags(search_add_fork_filter_to_zoekt: false)
            end

            it_behaves_like 'a non-filtered search'
          end
        end

        context 'when include_forked filter is set to false' do
          let(:filters) { { include_forked: false } }

          it 'calls search on Gitlab::Search::Zoekt::Client with non archived project ids' do
            expect(Gitlab::Search::Zoekt::Client).to receive(:search).with(
              query,
              num: described_class::ZOEKT_COUNT_LIMIT,
              project_ids: non_forked_project_ids,
              node_id: node_id,
              search_mode: :exact
            ).and_call_original

            search
          end

          context 'and all projects are forked' do
            let(:limit_projects) { ::Project.id_in(forked_project.id) }

            it 'returns an empty result set' do
              expect(Gitlab::Search::Zoekt::Client).not_to receive(:search)

              expect(search).to be_empty
            end
          end

          context 'when search_add_fork_filter_to_zoekt flag is disabled' do
            before do
              stub_feature_flags(search_add_fork_filter_to_zoekt: false)
            end

            it_behaves_like 'a non-filtered search'
          end
        end
      end
    end
  end
end
