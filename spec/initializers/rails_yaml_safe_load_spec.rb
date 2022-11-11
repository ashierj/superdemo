# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rails YAML safe load' do
  let(:unsafe_load) { false }

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'issues'

      serialize :description
    end
  end

  let(:instance) { klass.new(description: data) }

  context 'with default permitted classes' do
    let(:data) do
      {
        'time' => Time.now,
        'date' => Date.today,
        'number' => 1,
        'hashie-array' => Hashie::Array.new([1, 2]),
        'array' => [5, 6]
      }
    end

    it 'deserializes data' do
      instance.save!

      expect(klass.find(instance.id).description).to eq(data)
    end

    context 'with unpermitted classes' do
      let(:data) { { 'test' => create(:user) } }

      it 'throws an exception' do
        expect { instance.save! }.to raise_error(Psych::DisallowedClass)
      end
    end
  end
end
