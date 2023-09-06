import { shallowMount } from '@vue/test-utils';
import SummaryNote from 'ee/merge_requests/components/summary_note.vue';
import SummaryNoteWrapper from 'ee/merge_requests/components/summary_note_wrapper.vue';

let wrapper;

function createComponent(summary) {
  wrapper = shallowMount(SummaryNote, {
    stubs: { SummaryNoteWrapper },
    propsData: { summary, type: 'summary' },
  });
}

describe('Merge request summary note component', () => {
  it('renders summary note', () => {
    const contentHtml = '<div>AI</div> content';
    createComponent({
      createdAt: 'created-at',
      contentHtml,
    });

    expect(wrapper.find('p').element.innerHTML).toBe(contentHtml);
  });

  it('renders review note', () => {
    const contentHtml = '<div>AI</div> content';
    const nestedSummary = { contentHtml: 'review', createdAt: 'created-at' };
    createComponent({
      createdAt: 'created-at',
      contentHtml,
      children: [nestedSummary],
    });

    expect(wrapper.find('p').element.innerHTML).toBe(contentHtml);
    expect(wrapper.findComponent('[data-testid="nested-note"]').props('summary')).toStrictEqual(
      nestedSummary,
    );
  });
});
