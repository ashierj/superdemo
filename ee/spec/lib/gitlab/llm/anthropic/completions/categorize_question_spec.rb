# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Anthropic::Completions::CategorizeQuestion, feature_category: :duo_chat do
  describe '#execute' do
    let(:user) { build(:user) }
    let(:ai_client) { ::Gitlab::Llm::Anthropic::Client.new(nil) }
    let(:response) {  { 'completion' => llm_analysis_response.to_s } }
    let(:llm_analysis_response) do
      {
        detailed_category: "Summarize issue",
        category: 'Summarize something',
        labels: %w[contains_code is_related_to_gitlab],
        language: 'en',
        extra: 'foo'
      }.to_json
    end

    let(:prompt_message) do
      build(:ai_message, :categorize_question, user: user, resource: user, request_id: 'uuid')
    end

    let(:message_id) { '<message_id>' }
    let(:options) { { question: 'What is the pipeline?', message_id: message_id } }
    let(:template_class) { ::Gitlab::Llm::Templates::CategorizeQuestion }
    let(:prompt) { '<prompt>' }

    subject(:categorize_action) do
      described_class.new(prompt_message, template_class, **options).execute
    end

    before do
      allow_next_instance_of(template_class) do |template|
        allow(template).to receive(:to_prompt).and_return(prompt)
      end
      allow_next_instance_of(::Gitlab::Llm::Anthropic::Client) do |ai_client|
        allow(ai_client).to receive(:complete).with(prompt: prompt).and_return(response)
      end
    end

    context 'with valid response' do
      it 'tracks event' do
        expect(categorize_action.errors).to be_empty

        expect_snowplow_event(
          category: described_class.to_s,
          action: 'ai_question_category',
          property: 'uuid',
          user: user,
          context: [{
            schema: described_class::SCHEMA_URL,
            data: {
              'detailed_category' => "Summarize issue",
              'category' => 'Summarize something',
              'contains_code' => true,
              "is_related_to_gitlab" => true,
              'language' => 'en'
            }
          }]
        )
      end
    end

    context 'with incomplete response' do
      let(:llm_analysis_response) { { category: 'Summarize something' }.to_json }

      it 'does not track event' do
        expect(categorize_action.errors).to include('Event not tracked')

        expect_no_snowplow_event(
          category: described_class.to_s,
          action: 'ai_question_category',
          property: 'uuid',
          user: user,
          context: anything
        )
      end
    end

    context 'with invalid response' do
      let(:llm_analysis_response) { "invalid" }

      it 'does not track event' do
        expect(categorize_action.errors).to include('Event not tracked')

        expect_no_snowplow_event(
          category: described_class.to_s,
          action: 'ai_question_category',
          property: 'uuid',
          user: user,
          context: anything
        )
      end
    end
  end
end
