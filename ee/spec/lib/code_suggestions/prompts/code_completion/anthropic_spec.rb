# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Prompts::CodeCompletion::Anthropic, feature_category: :code_suggestions do
  let(:prefix) { 'prefix' }
  let(:suffix) { 'suffix' }
  let(:filename) { 'test.py' }
  let(:params) do
    {
      current_file: {
        file_name: filename,
        content_above_cursor: prefix,
        content_below_cursor: suffix
      }
    }
  end

  subject { described_class.new(params) }

  it_behaves_like 'code suggestion prompt' do
    let(:request_params) do
      {
        model_provider: ::CodeSuggestions::AiModels::ANTHROPIC,
        prompt_version: 2,
        prompt: <<~PROMPT
          Human: We want to fill in new Python code between existing code.
          Here is the content of a Python file in the path 'test.py' enclosed
          in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
          Review the existing code to understand existing logic and format.
          Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
          If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.
          Do not repeat code that already exists. The new code has to be fully functional and complete.

          <existing_code>
            prefix<cursor>suffix
          </existing_code>

          Assistant: <new_code>
        PROMPT
      }
    end
  end

  context 'when prefix is missing' do
    let(:prefix) { '' }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          model_provider: ::CodeSuggestions::AiModels::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: We want to fill in new Python code between existing code.
            Here is the content of a Python file in the path 'test.py' enclosed
            in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
            Review the existing code to understand existing logic and format.
            Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.
            Do not repeat code that already exists. The new code has to be fully functional and complete.

            <existing_code>
              <cursor>suffix
            </existing_code>

            Assistant: <new_code>
          PROMPT
        }
      end
    end
  end

  context 'when suffix is missing' do
    let(:suffix) { '' }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          model_provider: ::CodeSuggestions::AiModels::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: We want to fill in new Python code between existing code.
            Here is the content of a Python file in the path 'test.py' enclosed
            in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
            Review the existing code to understand existing logic and format.
            Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.
            Do not repeat code that already exists. The new code has to be fully functional and complete.

            <existing_code>
              prefix<cursor>
            </existing_code>

            Assistant: <new_code>
          PROMPT
        }
      end
    end
  end

  context 'when filename is missing' do
    let(:filename) { '' }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          model_provider: ::CodeSuggestions::AiModels::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: We want to fill in new  code between existing code.
            Here is the content of a  file in the path '' enclosed
            in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
            Review the existing code to understand existing logic and format.
            Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.
            Do not repeat code that already exists. The new code has to be fully functional and complete.

            <existing_code>
              prefix<cursor>suffix
            </existing_code>

            Assistant: <new_code>
          PROMPT
        }
      end
    end
  end
end
