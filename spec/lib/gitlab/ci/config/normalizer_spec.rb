# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Config::Normalizer do
  let(:job_name) { :rspec }
  let(:job_config) { { script: 'rspec', parallel: 5, name: 'rspec' } }
  let(:config) { { job_name => job_config } }

  describe '.normalize_jobs' do
    subject { described_class.normalize_jobs(config) }

    it 'does not have original job' do
      is_expected.not_to include(job_name)
    end

    it 'has parallelized jobs' do
      job_names = described_class.send(:parallelize_job_names, job_name, 5).map { |job_name, index| job_name.to_sym }

      is_expected.to include(*job_names)
    end

    it 'sets job instance in options' do
      expect(subject.values).to all(include(:instance))
    end

    it 'parallelizes jobs with original config' do
      original_config = config[job_name].except(:name)
      configs = subject.values.map { |config| config.except(:name, :instance) }

      expect(configs).to all(eq(original_config))
    end

    context 'when jobs depend on parallelized jobs' do
      let(:config) { { job_name => job_config, other_job: { script: 'echo 1', dependencies: [job_name.to_s] } } }

      it 'parallelizes dependencies' do
        job_names = described_class.send(:parallelize_job_names, job_name, 5).map(&:first)

        expect(subject[:other_job][:dependencies]).to include(*job_names)
      end
    end
  end

  describe '.parallelize_job_names' do
    subject { described_class.send(:parallelize_job_names, job_name, 5) }

    it 'returns parallelized names' do
      expect(subject.map(&:first)).to all(match(%r{#{job_name} \d+/\d+}))
    end
  end
end
