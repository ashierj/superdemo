# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::TanukiBot, feature_category: :duo_chat do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:embeddings) { create_list(:vertex_gitlab_documentation, 2) }

    let(:empty_response_message) { "I'm sorry, I was not able to find any documentation to answer your question." }
    let(:question) { 'A question' }
    let(:answer) { 'The answer.' }
    let(:logger) { instance_double('Gitlab::Llm::Logger') }
    let(:instance) { described_class.new(current_user: user, question: question, logger: logger) }
    let(:vertex_model) { ::Embedding::Vertex::GitlabDocumentation }
    let(:vertex_args) { { content: question } }
    let(:vertex_client) { ::Gitlab::Llm::VertexAi::Client.new(user) }
    let(:anthropic_client) { ::Gitlab::Llm::Anthropic::Client.new(user) }
    let(:embedding) { Array.new(1536, 0.5) }
    let(:vertex_embedding) { Array.new(768, 0.5) }
    let(:openai_response) { { "data" => [{ "embedding" => embedding }] } }
    let(:vertex_response) { { "predictions" => [{ "embeddings" => { "values" => vertex_embedding } }] } }
    let(:attrs) { embeddings.map(&:id).map { |x| "CNT-IDX-#{x}" }.join(", ") }
    let(:completion_response) { "#{answer} ATTRS: #{attrs}" }

    let(:status_code) { 200 }
    let(:success) { true }

    subject(:execute) { instance.execute }

    describe '.enabled_for?', :saas, :use_clean_rails_redis_caching do
      let_it_be_with_reload(:group) { create(:group_with_plan, plan: :ultimate_plan) }

      context 'when user present and container is not present' do
        where(:ai_global_switch_enabled, :ai_features_available_to_user, :result) do
          [
            [true, true, true],
            [true, false, false],
            [false, true, false],
            [false, false, false]
          ]
        end

        with_them do
          before do
            stub_feature_flags(ai_global_switch: ai_global_switch_enabled)
            allow(user).to receive(:any_group_with_ai_available?).and_return(ai_features_available_to_user)
          end

          it 'returns correct result' do
            expect(described_class.enabled_for?(user: user)).to be(result)
          end
        end
      end

      context 'when user and container are both present' do
        context 'when container is a group with AI enabled' do
          include_context 'with ai features enabled for group'

          context 'when user is a member of the group' do
            before_all do
              group.add_guest(user)
            end

            context 'when container is a group' do
              it 'returns true' do
                expect(
                  described_class.enabled_for?(user: user, container: group)
                ).to be(true)
              end
            end

            context 'when container is a project' do
              let_it_be(:project) { create(:project, group: group) }

              it 'returns true' do
                expect(
                  described_class.enabled_for?(user: user, container: project)
                ).to be(true)
              end
            end

            context 'when the group does not have an Ultimate SaaS license' do
              let_it_be(:group) { create(:group) }

              it 'returns false' do
                allow(user).to receive(:any_group_with_ai_available?).and_return(true)
                # add user as a member of the non-licensed group to ensure the
                # test isn't failing at the membership check
                group.add_guest(user)

                expect(
                  described_class.enabled_for?(user: user, container: group)
                ).to be(false)
              end
            end
          end

          context 'when user is not a member of the group' do
            context 'when the user has AI enabled via another group' do
              it 'returns false' do
                allow(user).to receive(:any_group_with_ai_available?).and_return(true)

                expect(
                  described_class.enabled_for?(user: user, container: group)
                ).to be(false)
              end
            end
          end
        end

        context 'when container is not a group with AI enabled' do
          context 'when user has AI enabled' do
            before do
              allow(user).to receive(:any_group_with_ai_available?).and_return(true)
            end

            context 'when container is a group' do
              include_context 'with experiment features disabled for group'

              it 'returns false' do
                allow(user).to receive(:any_group_with_ai_available?).and_return(true)

                expect(
                  described_class.enabled_for?(user: user, container: group)
                ).to be(false)
              end
            end

            context 'when container is a project in a personal namespace' do
              let_it_be(:project) { create(:project, namespace: user.namespace) }

              it 'returns false' do
                expect(
                  described_class.enabled_for?(user: user, container: project)
                ).to be(false)
              end
            end
          end
        end
      end

      context 'when user not present, container is present' do
        include_context 'with ai features enabled for group'

        it 'returns false' do
          expect(
            described_class.enabled_for?(user: nil, container: group)
          ).to be(false)
        end
      end
    end

    describe '.show_breadcrumbs_entry_point' do
      where(:tanuki_bot_breadcrumbs_feature_flag_enabled, :ai_features_enabled_for_user, :result) do
        [
          [true, true, true],
          [true, false, false],
          [false, true, false],
          [false, false, false]
        ]
      end

      with_them do
        before do
          stub_feature_flags(tanuki_bot_breadcrumbs_entry_point: tanuki_bot_breadcrumbs_feature_flag_enabled)
          allow(described_class).to receive(:enabled_for?).with(user: user, container: nil)
            .and_return(ai_features_enabled_for_user)
        end

        it 'returns correct result' do
          expect(described_class.show_breadcrumbs_entry_point?(user: user)).to be(result)
        end
      end
    end

    describe 'execute' do
      before do
        allow(License).to receive(:feature_available?).and_return(true)
        allow(logger).to receive(:info_or_debug)
      end

      context 'with the ai_tanuki_bot license not available' do
        before do
          allow(License).to receive(:feature_available?).with(:ai_tanuki_bot).and_return(false)
        end

        it 'returns an empty response message' do
          expect(execute.response_body).to eq(empty_response_message)
        end
      end

      context 'with the tanuki_bot license available' do
        context 'when on Gitlab.com' do
          before do
            allow(::Gitlab).to receive(:com?).and_return(true)
          end

          context 'when no user is provided' do
            let(:user) { nil }

            it 'returns an empty response message' do
              expect(execute.response_body).to eq(empty_response_message)
            end
          end

          context 'when user has AI features disabled' do
            before do
              allow(described_class).to receive(:enabled_for?).with(user: user).and_return(false)
            end

            it 'returns an empty response message' do
              expect(execute.response_body).to eq(empty_response_message)
            end
          end

          context 'when user has AI features enabled' do
            before do
              allow(::Gitlab::Llm::VertexAi::Client).to receive(:new).and_return(vertex_client)
              allow(::Gitlab::Llm::Anthropic::Client).to receive(:new).and_return(anthropic_client)
              allow(described_class).to receive(:enabled_for?).and_return(true)
            end

            context 'when embeddings table is empty (no embeddings are stored in the table)' do
              it 'returns an empty response message' do
                vertex_model.connection.execute("truncate #{vertex_model.table_name}")

                expect(execute.response_body).to eq(empty_response_message)
              end
            end

            it 'executes calls through to anthropic' do
              embeddings

              expect(anthropic_client).to receive(:stream).once.and_return(completion_response)
              expect(vertex_client).to receive(:text_embeddings).with(**vertex_args).and_return(vertex_response)

              execute
            end

            it 'calls the duo_chat_documentation pipeline for the emedded content' do
              allow(vertex_client).to receive(:text_embeddings).with(**vertex_args).and_return(vertex_response)
              allow(Banzai).to receive(:render).and_return('absolute_links_content')

              expect(anthropic_client).to receive(:stream)
                .with(
                  prompt: a_string_including('absolute_links_content'),
                  options: { model: "claude-instant-1.1" }
                ).once.and_return(completion_response)

              execute
            end

            it 'yields the streamed response to the given block' do
              embeddings

              allow(anthropic_client).to receive(:stream).once
                                           .and_yield({ "completion" => answer })
                                           .and_return(completion_response)

              expect(vertex_client).to receive(:text_embeddings).with(**vertex_args).and_return(vertex_response)

              expect { |b| instance.execute(&b) }.to yield_with_args(answer)
            end

            it 'raises an error when request failed' do
              embeddings

              expect(logger).to receive(:info).with(message: "Streaming error", error: { "message" => "some error" })
              expect(vertex_client).to receive(:text_embeddings).with(**vertex_args).and_return(vertex_response)
              allow(anthropic_client).to receive(:stream).once.and_yield({ "error" => { "message" => "some error" } })

              execute
            end
          end
        end

        context 'when ai_global_switch FF is disabled' do
          before do
            stub_feature_flags(ai_global_switch: false)
          end

          it 'returns an empty response message' do
            expect(execute.response_body).to eq(empty_response_message)
          end
        end

        context 'when the feature flags are enabled' do
          before do
            allow(::Gitlab::Llm::VertexAi::Client).to receive(:new).and_return(vertex_client)
            allow(::Gitlab::Llm::Anthropic::Client).to receive(:new).and_return(anthropic_client)
            allow(user).to receive(:any_group_with_ai_available?).and_return(true)
          end

          context 'when the question is not provided' do
            let(:question) { nil }

            it 'returns an empty response message' do
              expect(execute.response_body).to eq(empty_response_message)
            end
          end

          context 'when no neighbors are found' do
            before do
              allow(vertex_model).to receive(:neighbor_for).and_return(vertex_model.none)
              allow(vertex_client).to receive(:text_embeddings).with(**vertex_args).and_return(vertex_response)
            end

            it 'returns an i do not know' do
              expect(execute.response_body).to eq(empty_response_message)
            end
          end
        end
      end
    end
  end
end
