# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardHelper, type: :helper do
  let(:user) { build(:user) }

  describe '.has_start_trial?', :do_not_mock_admin_mode_setting do
    using RSpec::Parameterized::TableSyntax

    where(:has_license, :current_user, :output) do
      false | :admin | true
      false | :user  | false
      true  | :admin | false
      true  | :user  | false
    end

    with_them do
      let(:user) { create(current_user) } # rubocop:disable Rails/SaveBang
      let(:license) { has_license && create(:license) }
      subject { helper.has_start_trial? }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(License).to receive(:current).and_return(license)
      end

      it { is_expected.to eq(output) }
    end
  end
end
