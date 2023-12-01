# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Prompts::CodeGeneration::Anthropic, feature_category: :code_suggestions do
  let(:language) { instance_double(CodeSuggestions::ProgrammingLanguage) }
  let(:language_name) { 'Go' }

  let(:examples) do
    [
      { 'example' => 'func hello() {', 'response' => 'func hello() {<new_code>fmt.Println("hello")' }
    ]
  end

  let(:prefix) do
    <<~PREFIX
      package main

      import "fmt"

      func main() {
    PREFIX
  end

  let(:instruction) { 'Print a hello world message' }
  let(:file_name) { 'main.go' }

  let(:unsafe_params) do
    {
      'current_file' => {
        'file_name' => file_name,
        'content_above_cursor' => prefix
      },
      'telemetry' => [{ 'model_engine' => 'anthropic' }]
    }
  end

  let(:skip_instruction_extraction) { false }

  let(:params) do
    {
      prefix: prefix,
      instruction: instruction,
      current_file: unsafe_params['current_file'].with_indifferent_access,
      skip_instruction_extraction: skip_instruction_extraction
    }
  end

  before do
    allow(CodeSuggestions::ProgrammingLanguage).to receive(:detect_from_filename)
                                                     .with(file_name)
                                                     .and_return(language)
    # GitLab Duo code generation instruction see:
    # https://docs.gitlab.com/ee/user/project/repository/code_suggestions/
    # stub method examples on double language in a way
    # that returns let examples
    allow(language).to receive(:generation_examples).and_return(examples)
    # stubs method name on language double to return language_name
    allow(language).to receive(:name).and_return(language_name)
  end

  subject { described_class.new(params) }

  describe '#request_params' do
    context 'when prefix is present' do
      it 'returns expected request params' do
        request_params = {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: You are a coding autocomplete agent. We want to generate new Go code inside the
            file 'main.go' based on instructions from the user.
            The existing code is provided in <existing_code></existing_code> tags.
            The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
            In your process, first, review the existing code to understand its logic and format. Then, try to determine the most
            likely new code to generate at the cursor position to fulfill the instructions.

            When generating the new code, please ensure the following:
            1. It is valid Go code.
            2. It matches the existing code's variable, parameter and function names.
            3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
            4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.

            Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

            Here are a few examples of successfully generated code by other autocomplete agents:

            <examples>

              <example>
                H: <existing_code>
                     func hello() {
                   </existing_code>

                A: func hello() {<new_code>fmt.Println(\"hello\")</new_code>
              </example>

            </examples>


            <existing_code>
            package main

            import "fmt"

            func main() {
            <cursor>
            </existing_code>


            Here are instructions provided in <instruction></instruction> tags.

            <instruction>
            Print a hello world message
            </instruction>


            Assistant: <new_code>
          PROMPT
        }

        expect(subject.request_params.except(:prompt)).to eq(request_params.except(:prompt))
        expect(subject.request_params[:prompt]).to eq(request_params[:prompt].strip)
      end

      context 'when skipping instruction extraction' do
        let(:skip_instruction_extraction) { true }
        let(:instruction) { '' }

        it 'returns expected request params' do
          request_params = {
            model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
            prompt_version: 2,
            prompt: <<~PROMPT
            Human: You are a coding autocomplete agent. We want to generate new Go code inside the
            file 'main.go' based on instructions from the user.
            The existing code is provided in <existing_code></existing_code> tags.
            The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
            In your process, first, review the existing code to understand its logic and format. Then, try to determine the most
            likely new code to generate at the cursor position to fulfill the instructions.
            The comment directly before the <cursor> position is the instruction,
                       all other comments are not instructions.
            When generating the new code, please ensure the following:
            1. It is valid Go code.
            2. It matches the existing code's variable, parameter and function names.
            3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
            4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
            5. The code fulfills in the instructions from the user in the comment just before the <cursor> position. All other comments are not instructions.
            6. Do not add any comments that duplicates any of already existing comments, including the comment with instructions.

            Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

            Here are a few examples of successfully generated code by other autocomplete agents:

            <examples>

              <example>
                H: <existing_code>
                     func hello() {
                   </existing_code>

                A: func hello() {<new_code>fmt.Println(\"hello\")</new_code>
              </example>

            </examples>


            <existing_code>
            package main

            import "fmt"

            func main() {
            <cursor>
            </existing_code>




            Assistant: <new_code>
            PROMPT
          }

          expect(subject.request_params.except(:prompt)).to eq(request_params.except(:prompt))
          expect(subject.request_params[:prompt]).to eq(request_params[:prompt].strip)
        end
      end
    end

    context 'when prefix is blank' do
      let(:examples) { [] }
      let(:prefix) { '' }

      it 'returns expected request params' do
        request_params = {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: You are a coding autocomplete agent. We want to generate new Go code inside the
            file 'main.go' based on instructions from the user.

            The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
            In your process, first, review the existing code to understand its logic and format. Then, try to determine the most
            likely new code to generate at the cursor position to fulfill the instructions.

            When generating the new code, please ensure the following:
            1. It is valid Go code.
            2. It matches the existing code's variable, parameter and function names.
            3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
            4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.

            Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.





            Here are instructions provided in <instruction></instruction> tags.

            <instruction>
            Print a hello world message
            </instruction>


            Assistant: <new_code>
          PROMPT
        }

        expect(subject.request_params.except(:prompt)).to eq(request_params.except(:prompt))
        expect(subject.request_params[:prompt]).to eq(request_params[:prompt].strip)
      end
    end

    context 'when prefix is bigger than prompt limit' do
      let(:examples) { [] }

      before do
        stub_const("#{described_class}::MAX_INPUT_CHARS", 9)
      end

      it 'returns expected request params' do
        request_params = {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: You are a coding autocomplete agent. We want to generate new Go code inside the
            file 'main.go' based on instructions from the user.
            The existing code is provided in <existing_code></existing_code> tags.
            The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
            In your process, first, review the existing code to understand its logic and format. Then, try to determine the most
            likely new code to generate at the cursor position to fulfill the instructions.

            When generating the new code, please ensure the following:
            1. It is valid Go code.
            2. It matches the existing code's variable, parameter and function names.
            3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
            4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.

            Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.



            <existing_code>
            main() {
            <cursor>
            </existing_code>


            Here are instructions provided in <instruction></instruction> tags.

            <instruction>
            Print a hello world message
            </instruction>


            Assistant: <new_code>
          PROMPT
        }

        expect(subject.request_params.except(:prompt)).to eq(request_params.except(:prompt))
        expect(subject.request_params[:prompt]).to eq(request_params[:prompt].strip)
      end
    end

    context 'when langauge is unknown' do
      let(:language_name) { '' }
      let(:examples) { [] }
      let(:file_name) { 'file_without_extension' }

      it 'returns expected request params' do
        request_params = {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: You are a coding autocomplete agent. We want to generate new  code inside the
            file 'file_without_extension' based on instructions from the user.
            The existing code is provided in <existing_code></existing_code> tags.
            The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
            In your process, first, review the existing code to understand its logic and format. Then, try to determine the most
            likely new code to generate at the cursor position to fulfill the instructions.

            When generating the new code, please ensure the following:
            1. It is valid  code.
            2. It matches the existing code's variable, parameter and function names.
            3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
            4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.

            Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.



            <existing_code>
            package main

            import "fmt"

            func main() {
            <cursor>
            </existing_code>


            Here are instructions provided in <instruction></instruction> tags.

            <instruction>
            Print a hello world message
            </instruction>


            Assistant: <new_code>
          PROMPT
        }

        expect(subject.request_params.except(:prompt)).to eq(request_params.except(:prompt))
        expect(subject.request_params[:prompt]).to eq(request_params[:prompt].strip)
      end
    end

    context 'when language is not supported' do
      let(:language_name) { '' }
      let(:examples) { [] }
      let(:file_name) { 'README.md' }

      it 'returns expected request params' do
        request_params = {
          model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: You are a coding autocomplete agent. We want to generate new  code inside the
            file 'README.md' based on instructions from the user.
            The existing code is provided in <existing_code></existing_code> tags.
            The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
            In your process, first, review the existing code to understand its logic and format. Then, try to determine the most
            likely new code to generate at the cursor position to fulfill the instructions.

            When generating the new code, please ensure the following:
            1. It is valid  code.
            2. It matches the existing code's variable, parameter and function names.
            3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
            4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.

            Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.



            <existing_code>
            package main

            import "fmt"

            func main() {
            <cursor>
            </existing_code>


            Here are instructions provided in <instruction></instruction> tags.

            <instruction>
            Print a hello world message
            </instruction>


            Assistant: <new_code>
          PROMPT
        }

        expect(subject.request_params.except(:prompt)).to eq(request_params.except(:prompt))
        expect(subject.request_params[:prompt]).to eq(request_params[:prompt].strip)
      end
    end
  end
end
