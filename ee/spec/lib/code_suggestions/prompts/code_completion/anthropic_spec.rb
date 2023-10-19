# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Prompts::CodeCompletion::Anthropic, feature_category: :code_suggestions do
  let(:prefix) { 'prefix' }
  let(:suffix) { 'suffix' }
  let(:filename) { 'test.py' }
  let(:language) { instance_double(CodeSuggestions::ProgrammingLanguage) }
  let(:language_name) { nil }
  let(:params) do
    {
      current_file: {
        file_name: filename,
        content_above_cursor: prefix,
        content_below_cursor: suffix
      }
    }
  end

  # GitLab Duo code generation instruction see:
  # https://docs.gitlab.com/ee/user/project/repository/code_suggestions/
  # generate let :examples that is an array with one hash
  # that has string keys example and response
  let(:examples) do
    [
      { 'example' => 'def hello():', 'response' => 'print("hello")' }
    ]
  end

  subject { described_class.new(params) }

  # GitLab Duo code generation instruction see:
  # https://docs.gitlab.com/ee/user/project/repository/code_suggestions/
  # using RSpec stub CodeSuggestions::ProgrammingLanguage#detect_from_filename to
  # return language double
  before do
    allow(CodeSuggestions::ProgrammingLanguage).to receive(:detect_from_filename)
    .with(filename)
    .and_return(language)
    # GitLab Duo code generation instruction see:
    # https://docs.gitlab.com/ee/user/project/repository/code_suggestions/
    # stub method examples on double language in a way
    # that returns let examples
    allow(language).to receive(:examples).and_return(examples)
    # stubs method name on language double to return language_name
    allow(language).to receive(:name).and_return(language_name)
  end

  it_behaves_like 'code suggestion prompt' do
    let(:language_name) { 'Python' }
    let(:request_params) do
      {
        model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
        prompt_version: 2,
        prompt: <<~PROMPT
          Human: We want to fill in new Python code between existing code.
          Here is the content of a Python file in the path 'test.py' enclosed
          in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
          Review the existing code to understand existing logic and format.
          Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
          If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.
          Do not repeat code that already exists.
          You got example scenarios between <examples> XML tag.

          <examples>

            <example>
              H: <existing_code>
                   def hello():
                 </existing_code>

              A: <new_code> print("hello")
            </example>

          </examples>

          The new code has to be fully functional and complete. Let's start, here is the existing code:

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
    let(:language_name) { 'Python' }
    let(:examples) { [] }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: We want to fill in new Python code between existing code.
            Here is the content of a Python file in the path 'test.py' enclosed
            in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
            Review the existing code to understand existing logic and format.
            Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.
            Do not repeat code that already exists.

            The new code has to be fully functional and complete. Let's start, here is the existing code:

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
    let(:language_name) { 'Python' }
    let(:examples) { [] }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: We want to fill in new Python code between existing code.
            Here is the content of a Python file in the path 'test.py' enclosed
            in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
            Review the existing code to understand existing logic and format.
            Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.
            Do not repeat code that already exists.

            The new code has to be fully functional and complete. Let's start, here is the existing code:

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
    let(:examples) { [] }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: We want to fill in new  code between existing code.
            Here is the content of a  file in the path '' enclosed
            in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
            Review the existing code to understand existing logic and format.
            Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.
            Do not repeat code that already exists.

            The new code has to be fully functional and complete. Let's start, here is the existing code:

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
