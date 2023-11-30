# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RunnersAvailabilityBuilder, :request_store,
  feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  subject(:builder) { described_class.instance_for(project) }

  describe '#self.instance_for' do
    it 'creates instance for the project' do
      expect(builder).to be_instance_of ::Gitlab::Ci::RunnersAvailabilityBuilder
    end

    context 'when more projects are using the builder' do
      let_it_be(:project2) { create(:project) }

      it 'caches instance for a specific project' do
        builder2 = described_class.instance_for(project)
        builder3 = described_class.instance_for(project2)

        expect(builder).to be_instance_of ::Gitlab::Ci::RunnersAvailabilityBuilder
        expect(builder2).to be_instance_of ::Gitlab::Ci::RunnersAvailabilityBuilder
        expect(builder3).to be_instance_of ::Gitlab::Ci::RunnersAvailabilityBuilder

        expect(builder2).to eq builder
        expect(builder3).not_to eq builder
      end
    end
  end

  describe '#minutes_checker' do
    it 'creates Gitlab::Ci::RunnersAvailability::Minutes availability checker' do
      expect(builder.minutes_checker).to be_instance_of ::Gitlab::Ci::RunnersAvailability::Minutes
    end

    it 'caches the result' do
      checker_1 = builder.minutes_checker
      checker_2 = builder.minutes_checker

      expect(checker_1).to be_instance_of ::Gitlab::Ci::RunnersAvailability::Minutes
      expect(checker_2).to be_instance_of ::Gitlab::Ci::RunnersAvailability::Minutes

      expect(checker_2).to eq checker_1
    end
  end
end
