# frozen_string_literal: true

RSpec.shared_examples 'ruby language' do
  let(:language_name) { 'Ruby' }

  subject { described_class.new(language_name).cursor_inside_empty_function?(content, suffix) }

  context 'when the cursor is at the end of the file' do
    let(:content) do
      <<~CONTENT
        def func1
          return 0
        end

        def index(arg1, arg2)

      CONTENT
    end

    let(:suffix) { '' }

    it { is_expected.to be_truthy }
  end

  context 'when cursor is inside an empty method but middle of the file' do
    let(:content) do
      <<~CONTENT
        def func1

      CONTENT
    end

    let(:suffix) do
      <<~SUFFIX
        def index2
          return 0
        end

        def index3(arg1)
          return 1
        end
      SUFFIX
    end

    it { is_expected.to be_truthy }
  end

  context 'when cursor in inside a non-empty method' do
    let(:content) do
      <<~CONTENT
        def func1

      CONTENT
    end

    let(:suffix) do
      <<~SUFFIX
          return 0
        end

        def index2
          return 'something'
        end
      SUFFIX
    end

    it { is_expected.to be_falsey }
  end

  context 'when cursor inside class method' do
    let(:content) do
      <<~CONTENT
        class User
          def initialize(f_name, l_name)
            @f_name = f_name
            @l_name = l_name
          end

          def full_name

      CONTENT
    end

    let(:suffix) { '' }

    it { is_expected.to be_truthy }
  end

  context 'when cursor inside the method with multiple spaces' do
    let(:content) do
      <<~CONTENT
        def func1



      CONTENT
    end

    let(:suffix) do
      <<~SUFFIX
        def index2
          return 0
        end

        def index3(arg1)
          return 1
        end
      SUFFIX
    end

    it { is_expected.to be_truthy }
  end

  context 'when cursor is inside an empty method with comments with end keyword' do
    let(:content) do
      <<~CONTENT
        def index4(arg1, arg2)
          return 1
        end

        def func1

      CONTENT
    end

    let(:suffix) do
      <<~SUFFIX
        end

        def index2
          return 0
        end

        def index3(arg1)
          return 1
        end
      SUFFIX
    end

    it { is_expected.to be_truthy }
  end

  context 'when language in different that the given' do
    let(:content) do
      <<~CONTENT
        def index4(arg1, arg2):
          return 1

        def func1():

      CONTENT
    end

    let(:suffix) do
      <<~SUFFIX
        def index2():
          return 0

        def index3(arg1):
          return 1

      SUFFIX
    end

    it { is_expected.to be_falsey }
  end
end
