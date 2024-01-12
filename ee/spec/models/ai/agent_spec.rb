# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::Agent, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:existing_agent) { create(:ai_agent, name: 'an_existing_agent', project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:versions) }
  end

  describe 'validation' do
    subject { build(:ai_agent) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to be_valid }

    describe 'name' do
      using RSpec::Parameterized::TableSyntax

      let(:name) { 'a_valid_name' }

      subject(:errors) do
        m = described_class.new(name: name, project: project)
        m.validate
        m.errors
      end

      it 'validates a valid agent' do
        expect(errors).to be_empty
      end

      where(:ctx, :name) do
        'name is blank'                     | ''
        'name is not valid package name'    | '!!()()'
        'name is too large'                 | ('a' * 256)
        'name is not unique in the project' | 'an_existing_agent'
      end
      with_them do
        it { expect(errors).to include(:name) }
      end
    end
  end
end
