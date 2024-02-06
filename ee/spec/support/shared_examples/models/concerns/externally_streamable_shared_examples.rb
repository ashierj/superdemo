# frozen_string_literal: true

RSpec.shared_examples 'includes ExternallyStreamable concern' do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:config) }
    it { is_expected.to validate_presence_of(:secret_token) }
    it { is_expected.to validate_presence_of(:type) }
    it { is_expected.to be_a(AuditEvents::ExternallyStreamable) }
    it { is_expected.to validate_length_of(:name).is_at_most(72) }

    context 'when type' do
      it 'is valid' do
        expect(destination).to be_valid
      end

      it 'is nil' do
        destination.type = nil

        expect(destination).not_to be_valid
        expect(destination.errors.full_messages)
          .to match_array(["Type can't be blank"])
      end

      it 'is invalid' do
        expect { destination.type = 'invalid' }.to raise_error(ArgumentError)
      end
    end

    it_behaves_like 'having unique enum values'

    context 'when config' do
      it 'is invalid' do
        destination.config = 'hello'

        expect(destination).not_to be_valid
        expect(destination.errors.full_messages).to include('Config must be a valid json schema')
      end
    end

    context 'when creating without a name' do
      before do
        allow(SecureRandom).to receive(:uuid).and_return('12345678')
      end

      it 'assigns a default name' do
        destination = build(model_factory_name, name: nil)

        expect(destination).to be_valid
        expect(destination.name).to eq('Destination_12345678')
      end
    end
  end
end
