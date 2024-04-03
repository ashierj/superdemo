# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::AiResource::Epic, feature_category: :duo_chat do
  let(:epic) { build(:epic) }
  let(:user) { build(:user) }

  subject(:wrapped_epic) { described_class.new(epic) }

  describe '#serialize_for_ai' do
    it 'calls the serializations class' do
      expect(EpicSerializer).to receive_message_chain(:new, :represent)
                                  .with(current_user: user)
                                  .with(epic, {
                                    user: user,
                                    notes_limit: 100,
                                    serializer: 'ai',
                                    resource: wrapped_epic
                                  })

      wrapped_epic.serialize_for_ai(user: user, content_limit: 100)
    end
  end

  describe '#current_page_sentence' do
    it 'returns prompt' do
      expect(wrapped_epic.current_page_sentence).to include("utilize it instead of using the 'EpicReader' tool")
    end

    context 'when ai_prompt_current_page_skip_reader is off' do
      it 'returns older prompt' do
        stub_feature_flags(ai_prompt_current_page_skip_reader: false)

        expect(wrapped_epic.current_page_sentence).to include('Here is additional data in <resource></resource> tags')
      end
    end
  end
end
