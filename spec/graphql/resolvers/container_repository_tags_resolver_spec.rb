# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ContainerRepositoryTagsResolver, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:repository) { create(:container_repository, project: project) }

  let(:args) { { sort: nil } }

  describe '#resolve' do
    shared_examples 'fetching via tags and filter in place' do
      context 'by name' do
        subject { resolver(args).map(&:name) }

        before do
          stub_container_registry_tags(repository: repository.path, tags: %w[aaa bab bbb ccc 123], with_manifest: false)
        end

        context 'without sort' do
          # order is not guaranteed
          it { is_expected.to contain_exactly('aaa', 'bab', 'bbb', 'ccc', '123') }
        end

        context 'with sorting and filtering' do
          context 'name_asc' do
            let(:args) { { sort: 'NAME_ASC' } }

            it { is_expected.to eq(%w[123 aaa bab bbb ccc]) }
          end

          context 'name_desc' do
            let(:args) { { sort: 'NAME_DESC' } }

            it { is_expected.to eq(%w[ccc bbb bab aaa 123]) }
          end

          context 'filter by name' do
            let(:args) { { sort: 'NAME_DESC', name: 'b' } }

            it { is_expected.to eq(%w[bbb bab]) }
          end
        end
      end
    end

    before do
      stub_container_registry_config(enabled: true)
    end

    context 'when Gitlab API is supported', :saas do
      before do
        allow(repository).to receive(:tags_page).and_return({
          tags: [],
          pagination: {
            previous: { uri: URI('/test?before=prev-cursor') },
            next: { uri: URI('/test?last=next-cursor') }
          }
        })

        allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
      end

      context 'get the page size based on first and last param' do
        it 'sends the page size based on first if next page is asked' do
          args = { sort: 'NAME_ASC', first: 10 }
          expect(repository).to receive(:tags_page).with(hash_including(page_size: args[:first]))

          resolver(args)
        end

        it 'sends the page size based on last if prev page is asked' do
          args = { sort: 'NAME_ASC', last: 10 }
          expect(repository).to receive(:tags_page).with(hash_including(page_size: args[:last]))

          resolver(args)
        end
      end

      context 'with parameters' do
        using RSpec::Parameterized::TableSyntax

        where(:before, :after, :sort, :name, :first, :last, :sort_value, :referrers, :referrer_type) do
          nil  | nil  | 'NAME_DESC' | ''  | 10  | nil | '-name' | nil   | nil
          'bb' | nil  | 'NAME_ASC'  | 'a' | nil | 5   | 'name'  | false | nil
          nil  | 'aa' | 'NAME_DESC' | 'a' | 10  | nil | '-name' | true  | 'application/example'
        end

        with_them do
          let(:args) do
            { before: before, after: after, sort: sort, name: name, first: first,
              last: last, referrers: referrers, referrer_type: referrer_type }.compact
          end

          it 'calls ContainerRepository#tags_page with correct parameters' do
            expect(repository).to receive(:tags_page).with(
              before: before,
              last: after,
              sort: sort_value,
              name: name,
              page_size: [first, last].map(&:to_i).max,
              referrers: referrers,
              referrer_type: referrer_type
            )

            resolver(args)
          end
        end
      end

      it 'returns an ExternallyPaginatedArray' do
        expect(Gitlab::Graphql::ExternallyPaginatedArray)
          .to receive(:new).with('prev-cursor', 'next-cursor')

        expect(resolver(args)).is_a? Gitlab::Graphql::ExternallyPaginatedArray
      end
    end

    context 'when Gitlab API is not supported' do
      before do
        allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)
      end

      it_behaves_like 'fetching via tags and filter in place'
    end

    def resolver(args, opts = {})
      field_options = {
        owner: resolver_parent,
        resolver: described_class,
        connection_extension: Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension
      }.merge(opts)

      field = ::Types::BaseField.from_options('field_value', **field_options)
      resolve_field(field, repository, args: args, object_type: resolver_parent)
    end
  end
end
