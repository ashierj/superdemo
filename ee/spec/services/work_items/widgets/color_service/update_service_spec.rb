# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::ColorService::UpdateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:work_item) { create(:work_item, :epic, namespace: group, author: user) }
  let_it_be_with_reload(:color) { create(:color, work_item: work_item, color: '#1068bf') }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Color) } }

  def work_item_color
    work_item.reload.color&.color.to_s
  end

  describe '#before_update_in_transaction' do
    let(:service) { described_class.new(widget: widget, current_user: user) }

    subject { service.before_update_in_transaction(params: params) }

    shared_examples 'work item and color is unchanged' do
      it 'does not change work item color value' do
        expect { subject }
          .to not_change { work_item_color }
          .and not_change { work_item.updated_at }
      end

      it 'does not create notes' do
        expect { subject }.to not_change(work_item.notes, :count)
      end
    end

    shared_examples 'color is updated' do |color|
      it 'updates work item color value' do
        expect { subject }.to change { work_item_color }.to(color)
      end

      it 'creates notes' do
        subject

        work_item_note = work_item.notes.last
        expect(work_item_note.note).to eq("changed color to `#{color}`")
      end
    end

    shared_examples 'raises a WidgetError' do
      it { expect { subject }.to raise_error(described_class::WidgetError, message) }
    end

    context 'when epic_colors feature is licensed' do
      before do
        stub_licensed_features(epic_colors: true)
      end

      context 'when user cannot update work item' do
        let(:params) { { color: '#1068bf' } }

        before_all do
          group.add_guest(user)
        end

        it_behaves_like 'work item and color is unchanged'
      end

      context 'when user can update work item' do
        before_all do
          group.add_reporter(user)
        end

        context 'when color param is present' do
          context 'when color param is valid' do
            let(:params) { { color: '#454545' } }

            it_behaves_like 'color is updated', '#454545'
          end

          context 'when widget does not exist in new type' do
            let(:params) { {} }

            before do
              allow(service).to receive(:new_type_excludes_widget?).and_return(true)
              work_item.color = color
            end

            it "removes the work item's color" do
              expect { service.before_update_in_transaction(params: params) }.to change {
                                                                                   work_item.reload.color
                                                                                 }.from(color).to(nil)

              work_item_note = work_item.notes.last
              expect(work_item_note.note).to eq("removed the color `#1068bf`")
            end
          end
        end

        context 'when color param is not present' do
          let(:params) { {} }

          it_behaves_like 'work item and color is unchanged'
        end

        context 'when color is same as work item color' do
          let(:params) { { color: '#1068bf' } }

          it_behaves_like 'work item and color is unchanged'
        end

        context 'when color param is nil' do
          let(:params) { { color: nil } }

          it_behaves_like 'raises a WidgetError' do
            let(:message) { "Color can't be blank" }
          end
        end
      end
    end
  end
end
