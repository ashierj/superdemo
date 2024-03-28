# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Components::Usages::CreateService, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:component) { create(:ci_catalog_resource_component) }

  let(:service) { described_class.new(component, used_by_project: project) }

  describe '#execute' do
    subject(:execute) { service.execute }

    it 'creates a usage record', :aggregate_failures do
      expect { execute }.to change { Ci::Catalog::Resources::Components::Usage.count }.by(1)
      expect(execute).to be_success
      expect(execute.message).to eq('Usage recorded')

      usage = Ci::Catalog::Resources::Components::Usage.find_by(component: component)

      expect(usage.catalog_resource).to eq(component.catalog_resource)
      expect(usage.project).to eq(component.project)
      expect(usage.used_by_project_id).to eq(project.id)
    end

    context 'when usage has already been recorded', :freeze_time do
      it 'does not create a usage record' do
        service.execute

        expect { execute }.not_to change { Ci::Catalog::Resources::Components::Usage.count }
        expect(execute).to be_success
        expect(execute.message).to eq('Usage already recorded for today')
      end
    end

    context 'when usage is invalid' do
      it 'does not create a usage record and returns error' do
        usage = instance_double(
          Ci::Catalog::Resources::Components::Usage, valid?: false,
          errors: instance_double(ActiveModel::Errors, full_messages: ['msg 1', 'msg 2'], size: 2))

        allow(Ci::Catalog::Resources::Components::Usage).to receive(:new).and_return(usage)

        expect { execute }.not_to change { Ci::Catalog::Resources::Components::Usage.count }
        expect(execute).to be_error
        expect(execute.message).to eq('msg 1, msg 2')
      end
    end
  end
end
