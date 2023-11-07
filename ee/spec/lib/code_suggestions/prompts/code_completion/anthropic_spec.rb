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
      { 'example' => 'def hello():', 'response' => '<new_code>print("hello")' }
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
    allow(language).to receive(:completion_examples).and_return(examples)
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
          Human: You are a coding autocomplete agent. We want to generate new Python code inside the file 'test.py'.
          The existing code is provided in <existing_code></existing_code> tags.
          The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
          In your process, first, review the existing code to understand its logic and format. Then, try to determine the most likely new code to generate at the cursor position.
          When generating the new code, please ensure the following:
          1. It is valid Python code.
          2. It matches the existing code's variable, parameter and function names.
          3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
          4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
          Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
          If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

          Here are a few examples of successfully generated code by other autocomplete agents:

          <examples>

            <example>
              H: <existing_code>
                   def hello():
                 </existing_code>

              A: <new_code>print(\"hello\")</new_code>
            </example>

          </examples>


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
          Human: You are a coding autocomplete agent. We want to generate new Python code inside the file 'test.py'.
          The existing code is provided in <existing_code></existing_code> tags.
          The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
          In your process, first, review the existing code to understand its logic and format. Then, try to determine the most likely new code to generate at the cursor position.
          When generating the new code, please ensure the following:
          1. It is valid Python code.
          2. It matches the existing code's variable, parameter and function names.
          3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
          4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
          Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
          If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

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
          Human: You are a coding autocomplete agent. We want to generate new Python code inside the file 'test.py'.
          The existing code is provided in <existing_code></existing_code> tags.
          The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
          In your process, first, review the existing code to understand its logic and format. Then, try to determine the most likely new code to generate at the cursor position.
          When generating the new code, please ensure the following:
          1. It is valid Python code.
          2. It matches the existing code's variable, parameter and function names.
          3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
          4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
          Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
          If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

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
          Human: You are a coding autocomplete agent. We want to generate new  code inside the file ''.
          The existing code is provided in <existing_code></existing_code> tags.
          The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
          In your process, first, review the existing code to understand its logic and format. Then, try to determine the most likely new code to generate at the cursor position.
          When generating the new code, please ensure the following:
          1. It is valid  code.
          2. It matches the existing code's variable, parameter and function names.
          3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
          4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
          Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
          If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

          <existing_code>
            prefix<cursor>suffix
          </existing_code>

          Assistant: <new_code>
          PROMPT
        }
      end
    end
  end

  context 'when prefix is bigger than prompt limit' do
    let(:trimmed_prefix) { 'efix' }
    let(:examples) { [] }
    let(:language_name) { 'Python' }

    before do
      stub_const("#{described_class}::MAX_INPUT_CHARS", 4)
    end

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
          Human: You are a coding autocomplete agent. We want to generate new Python code inside the file 'test.py'.
          The existing code is provided in <existing_code></existing_code> tags.
          The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
          In your process, first, review the existing code to understand its logic and format. Then, try to determine the most likely new code to generate at the cursor position.
          When generating the new code, please ensure the following:
          1. It is valid Python code.
          2. It matches the existing code's variable, parameter and function names.
          3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
          4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
          Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
          If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

            <existing_code>
              #{trimmed_prefix}<cursor>
            </existing_code>

            Assistant: <new_code>
          PROMPT
        }
      end
    end
  end

  context 'when prefix together with suffix is bigger than prompt limit' do
    let(:trimmed_suffix) { 'su' }
    let(:examples) { [] }
    let(:language_name) { 'Python' }

    before do
      stub_const("#{described_class}::MAX_INPUT_CHARS", 8)
    end

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
          Human: You are a coding autocomplete agent. We want to generate new Python code inside the file 'test.py'.
          The existing code is provided in <existing_code></existing_code> tags.
          The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
          In your process, first, review the existing code to understand its logic and format. Then, try to determine the most likely new code to generate at the cursor position.
          When generating the new code, please ensure the following:
          1. It is valid Python code.
          2. It matches the existing code's variable, parameter and function names.
          3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
          4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
          Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
          If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

            <existing_code>
              prefix<cursor>#{trimmed_suffix}
            </existing_code>

            Assistant: <new_code>
          PROMPT
        }
      end
    end
  end
end
