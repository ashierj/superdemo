# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Logger do
  describe '.build' do
    before do
      allow(described_class).to receive(:file_name_noext).and_return('log')
    end

    subject { described_class.build }

    it 'builds logger using Gitlab::Logger.log_level' do
      expect(described_class).to receive(:log_level).and_return(:warn)

      expect(subject.level).to eq(described_class::WARN)
    end

    it 'raises ArgumentError if invalid log level' do
      allow(described_class).to receive(:log_level).and_return(:invalid)

      expect { subject.level }.to raise_error(ArgumentError, 'invalid log level: invalid')
    end

    using RSpec::Parameterized::TableSyntax

    where(:env_value, :resulting_level) do
      0         | described_class::DEBUG
      :debug    | described_class::DEBUG
      'debug'   | described_class::DEBUG
      'DEBUG'   | described_class::DEBUG
      'DeBuG'   | described_class::DEBUG
      1         | described_class::INFO
      :info     | described_class::INFO
      'info'    | described_class::INFO
      'INFO'    | described_class::INFO
      'InFo'    | described_class::INFO
      2         | described_class::WARN
      :warn     | described_class::WARN
      'warn'    | described_class::WARN
      'WARN'    | described_class::WARN
      'WaRn'    | described_class::WARN
      3         | described_class::ERROR
      :error    | described_class::ERROR
      'error'   | described_class::ERROR
      'ERROR'   | described_class::ERROR
      'ErRoR'   | described_class::ERROR
      4         | described_class::FATAL
      :fatal    | described_class::FATAL
      'fatal'   | described_class::FATAL
      'FATAL'   | described_class::FATAL
      'FaTaL'   | described_class::FATAL
      5         | described_class::UNKNOWN
      :unknown  | described_class::UNKNOWN
      'unknown' | described_class::UNKNOWN
      'UNKNOWN' | described_class::UNKNOWN
      'UnKnOwN' | described_class::UNKNOWN
    end

    with_them do
      it 'builds logger if valid log level' do
        stub_env('GITLAB_LOG_LEVEL', env_value)

        expect(subject.level).to eq(resulting_level)
      end
    end
  end

  describe '.log_level' do
    context 'if GITLAB_LOG_LEVEL is set' do
      before do
        stub_env('GITLAB_LOG_LEVEL', described_class::ERROR)
      end

      it 'returns value of GITLAB_LOG_LEVEL' do
        expect(described_class.log_level).to eq(described_class::ERROR)
      end

      it 'ignores fallback' do
        expect(described_class.log_level(fallback: described_class::FATAL)).to eq(described_class::ERROR)
      end
    end

    context 'if GITLAB_LOG_LEVEL is not set' do
      it 'returns default fallback DEBUG' do
        expect(described_class.log_level).to eq(described_class::DEBUG)
      end

      it 'returns passed fallback' do
        expect(described_class.log_level(fallback: described_class::FATAL)).to eq(described_class::FATAL)
      end
    end
  end
end
