import { GlBadge, GlTable, GlTruncate } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import ListTable from 'ee_component/packages_and_registries/google_artifact_registry/components/list/table.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { imageData } from '../../mock_data';

describe('ListTable', () => {
  let wrapper;

  const defaultProps = {
    data: {
      nodes: [imageData],
    },
  };

  useFakeDate(2020, 1, 1);

  const findTable = () => wrapper.findComponent(GlTable);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findCells = () => wrapper.findAllByRole('cell');
  const findImageName = () => wrapper.findComponent(GlTruncate);
  const findBadges = () => wrapper.findAllComponents(GlBadge);
  const findFirstTag = () => findBadges().at(0).findComponent(GlTruncate);
  const findSecondTag = () => findBadges().at(1).findComponent(GlTruncate);
  const findMoreTagsBadge = () => findBadges().at(2);

  const createComponent = (propsData = defaultProps) => {
    wrapper = mountExtended(ListTable, {
      propsData,
      stubs: {
        GlTruncate: true,
        ClipboardButton: true,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders a table with the correct header fields', () => {
    expect(findTable().props('fields')).toEqual([
      {
        key: 'image',
        label: 'Name',
        thClass: 'gl-w-40p',
        tdClass: 'gl-pt-3!',
      },
      {
        key: 'tags',
        label: 'Tags',
        tdClass: 'gl-pt-4!',
      },
      {
        key: 'buildTime',
        label: 'Created',
      },
      {
        key: 'updateTime',
        label: 'Updated',
      },
    ]);
  });

  it('renders the image name and digest', () => {
    expect(findImageName().props('text')).toEqual('alpine@1234567890ab');
  });

  it('renders the clipboard button', () => {
    expect(findClipboardButton().props()).toMatchObject({
      text: 'alpine@sha256:1234567890abcdef1234567890abcdef12345678',
      title: 'Copy image name',
    });
  });

  describe('tags', () => {
    it('renders first tag', () => {
      expect(findFirstTag().props()).toMatchObject({
        text: 'latest',
        withTooltip: true,
      });
    });

    it('renders second tag', () => {
      expect(findSecondTag().props()).toMatchObject({
        text: 'v1.0.0',
        withTooltip: true,
      });
    });

    it('renders more tags badge when there is only one tag', () => {
      createComponent();
      expect(findMoreTagsBadge().text()).toEqual('+1');
      expect(findMoreTagsBadge().attributes('title')).toEqual('1 more tag');
    });

    it('renders more tags badge when there is more than one tag', () => {
      createComponent({
        data: {
          nodes: [
            {
              ...imageData,
              tags: ['latest', 'v1.0.0', 'v1.0.1', 'v1.0.2'],
            },
          ],
        },
      });

      expect(findMoreTagsBadge().text()).toEqual('+2');
      expect(findMoreTagsBadge().attributes('title')).toEqual('2 more tags');
    });

    it('does not render more tags badge', () => {
      createComponent({
        data: {
          nodes: [
            {
              ...imageData,
              tags: ['latest', 'v1.0.0'],
            },
          ],
        },
      });

      expect(findBadges()).toHaveLength(2);
    });

    it('does not render any tags', () => {
      createComponent({
        data: {
          nodes: [
            {
              ...imageData,
              tags: [],
            },
          ],
        },
      });

      expect(findBadges()).toHaveLength(0);
    });
  });

  it('renders the created time in the third column', () => {
    const createTimeCell = findCells().at(2);
    expect(createTimeCell.text()).toContain('1 year ago');
  });

  it('renders the update time in the fourth column', () => {
    const updateTimeCell = findCells().at(3);
    expect(updateTimeCell.text()).toContain('1 month ago');
  });
});
