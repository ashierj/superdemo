# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Experiment::Rollout::Feature, :experiment, feature_category: :acquisition do
  subject { described_class.new(subject_experiment) }

  let(:subject_experiment) { experiment('namespaced/stub') }

  describe "#enabled?", :saas do
    before do
      stub_feature_flags(gitlab_experiment: true)
      allow(subject).to receive(:feature_flag_defined?).and_return(true)
      allow(subject).to receive(:feature_flag_instance).and_return(double(state: :on))
    end

    it "is enabled when all criteria are met" do
      expect(subject).to be_enabled
    end

    it "isn't enabled if the feature definition doesn't exist" do
      expect(subject).to receive(:feature_flag_defined?).and_return(false)

      expect(subject).not_to be_enabled
    end

    it "isn't enabled if we're not in dev or dotcom environments" do
      expect(Gitlab).to receive(:com?).and_return(false)

      expect(subject).not_to be_enabled
    end

    it "isn't enabled if the feature flag state is :off" do
      expect(subject).to receive(:feature_flag_instance).and_return(double(state: :off))

      expect(subject).not_to be_enabled
    end

    it "isn't enabled if the gitlab_experiment feature flag is false" do
      stub_feature_flags(gitlab_experiment: false)

      expect(subject).not_to be_enabled
    end
  end

  describe "#execute_assignment" do
    let(:variants) do
      ->(e) do
        # rubocop:disable Lint/EmptyBlock
        e.control {}
        e.variant(:red) {}
        e.variant(:blue) {}
        # rubocop:enable Lint/EmptyBlock
      end
    end

    let(:subject_experiment) { experiment('namespaced/stub', &variants) }

    before do
      allow(Feature).to receive(:enabled?).with('namespaced_stub', any_args).and_return(true)
    end

    it "uses the default value as specified in the yaml" do
      expect(Feature).to receive(:enabled?).with(
        'namespaced_stub',
        subject,
        type: :experiment
      ).and_return(false)

      expect(subject.execute_assignment).to be_nil
    end

    it "returns an assigned name" do
      expect(subject.execute_assignment).to eq(:blue)
    end

    context "when there are no behaviors" do
      let(:variants) { ->(e) { e.control {} } } # rubocop:disable Lint/EmptyBlock

      it "does not raise an error" do
        expect { subject.execute_assignment }.not_to raise_error
      end
    end

    context "for even rollout to non-control", :saas do
      let(:counts) { Hash.new(0) }
      let(:subject_experiment) { experiment('namespaced/stub') }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:enabled?).and_return(true)
        end

        subject_experiment.variant(:variant1) {} # rubocop:disable Lint/EmptyBlock
        subject_experiment.variant(:variant2) {} # rubocop:disable Lint/EmptyBlock
      end

      it "rolls out relatively evenly to 2 behaviors" do
        100.times { |i| run_cycle(subject_experiment, value: i) }

        expect(counts).to eq(variant1: 54, variant2: 46)
      end

      it "rolls out relatively evenly to 3 behaviors" do
        subject_experiment.variant(:variant3) {} # rubocop:disable Lint/EmptyBlock

        100.times { |i| run_cycle(subject_experiment, value: i) }

        expect(counts).to eq(variant1: 31, variant2: 29, variant3: 40)
      end

      context "when distribution is specified as an array" do
        before do
          subject_experiment.rollout(described_class, distribution: [0, 32, 25, 43])
        end

        it "rolls out with the expected distribution" do
          subject_experiment.variant(:variant3) {} # rubocop:disable Lint/EmptyBlock

          100.times { |i| run_cycle(subject_experiment, value: i) }

          expect(counts).to eq(control: 2, variant1: 37, variant2: 24, variant3: 37)
        end
      end

      context "when distribution is specified as a hash" do
        before do
          subject_experiment.rollout(described_class, distribution: { control: 0, variant1: 90, variant2: 10 })
        end

        it "rolls out with the expected distribution" do
          100.times { |i| run_cycle(subject_experiment, value: i) }

          expect(counts).to eq(control: 2, variant1: 93, variant2: 5)
        end
      end

      def run_cycle(experiment, **context)
        experiment.instance_variable_set(:@_assigned_variant_name, nil)
        experiment.context(context) if context

        begin
          experiment.cache.delete
        rescue StandardError
          nil
        end

        counts[experiment.assigned.name] += 1
      end
    end
  end

  describe "#flipper_id" do
    it "returns the expected flipper id if the experiment doesn't provide one" do
      subject.instance_variable_set(:@experiment, double(id: '__id__'))
      expect(subject.flipper_id).to eq('Experiment;__id__')
    end

    it "lets the experiment provide a flipper id so it can override the default" do
      allow(subject_experiment).to receive(:flipper_id).and_return('_my_overridden_id_')

      expect(subject.flipper_id).to eq('_my_overridden_id_')
    end
  end
end
