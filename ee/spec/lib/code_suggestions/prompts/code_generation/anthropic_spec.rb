# frozen_string_literal: true

require 'spec_helper'
require_relative 'anthropic_shared_examples'

RSpec.describe CodeSuggestions::Prompts::CodeGeneration::Anthropic, feature_category: :code_suggestions do
  let(:prompt_version) { 2 }

  it_behaves_like 'anthropic prompt' do
    def expected_prompt
      <<~PROMPT.chomp
                                           Human: #{system_prompt}

                                           #{comment}

                                           Assistant: <new_code>
      PROMPT
    end
  end
end
