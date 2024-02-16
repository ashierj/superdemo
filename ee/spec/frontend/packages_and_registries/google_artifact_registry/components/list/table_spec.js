import Vue from 'vue';
import VueRouter from 'vue-router';
import { RouterLinkStub } from '@vue/test-utils';
import { GlBadge, GlTable, GlTruncate } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import ListTable from 'ee_component/packages_and_registries/google_artifact_registry/components/list/table.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { imageData } from '../../mock_data';

Vue.use(VueRouter);

describe('ListTable', () => {
  let wrapper;

  const getDefaultProps = (node = {}) => ({
    data: {
      nodes: [{ ...imageData, ...node }],
    },
    sort: {
      sortBy: 'name',
      sortDesc: true,
    },
  });

  useFakeDate(2020, 1, 1);

  const findTable = () => wrapper.findComponent(GlTable);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findImageLink = () => wrapper.findComponent(RouterLinkStub);
  const findCells = () => wrapper.findAllByRole('cell');
  const findImageName = () => wrapper.findComponent(GlTruncate);
  const findBadges = () => wrapper.findAllComponents(GlBadge);
  const findFirstTag = () => findBadges().at(0).findComponent(GlTruncate);
  const findSecondTag = () => findBadges().at(1).findComponent(GlTruncate);
  const findMoreTagsBadge = () => wrapper.findByTestId('more-tags-badge');
  const findMoreTagsScreenReaderText = () => wrapper.findByTestId('more-tags-badge-sr-text');

  const createComponent = (mountFn = shallowMountExtended, propsData = getDefaultProps()) => {
    wrapper = mountFn(ListTable, {
      propsData,
      stubs: {
        GlTruncate: true,
        ClipboardButton: true,
        RouterLink: RouterLinkStub,
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
        sortable: true,
      },
    ]);
  });

  it('sets the correct sort props', () => {
    expect(findTable().attributes()).toMatchObject({
      'sort-by': 'name',
      'sort-desc': 'true',
      'sort-icon-left': '',
      'no-sort-reset': '',
      'no-local-sorting': '',
    });
  });

  it('emits sort-changed event on sort', () => {
    findTable().vm.$emit('sort-changed', {
      sortBy: 'updateTime',
      sortDesc: false,
    });

    expect(wrapper.emitted('sort-changed')).toHaveLength(1);
    expect(wrapper.emitted('sort-changed')[0]).toEqual([
      {
        sortBy: 'updateTime',
        sortDesc: false,
      },
    ]);
  });

  describe('rows', () => {
    beforeEach(() => {
      createComponent(mountExtended);
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

    it('has a link to navigate to the details page', () => {
      expect(findImageLink().props('to')).toBe(imageData.name);
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

      it('renders more tag badge with aria-hidden', () => {
        expect(findMoreTagsBadge().attributes('aria-hidden')).toEqual('true');
      });

      it('renders "1 more tag" badge when there are three tags', () => {
        expect(findMoreTagsBadge().text()).toEqual('+1');
        expect(findMoreTagsBadge().attributes('title')).toEqual('1 more tag');
        expect(findMoreTagsScreenReaderText().text()).toEqual('1 more tag');
      });

      it('renders "2 more tags" badge when there are four tags', () => {
        createComponent(
          mountExtended,
          getDefaultProps({
            tags: ['latest', 'v1.0.0', 'v1.0.1', 'v1.0.2'],
          }),
        );

        expect(findMoreTagsBadge().text()).toEqual('+2');
        expect(findMoreTagsBadge().attributes('title')).toEqual('2 more tags');
        expect(findMoreTagsScreenReaderText().text()).toEqual('2 more tags');
      });

      it('does not render more tags badge', () => {
        createComponent(
          mountExtended,
          getDefaultProps({
            tags: ['latest', 'v1.0.0'],
          }),
        );

        expect(findMoreTagsBadge().exists()).toBe(false);
        expect(findMoreTagsScreenReaderText().exists()).toBe(false);
      });

      it('does not render any tags', () => {
        createComponent(
          mountExtended,
          getDefaultProps({
            tags: [],
          }),
        );

        expect(findBadges()).toHaveLength(0);
        expect(findMoreTagsBadge().exists()).toBe(false);
        expect(findMoreTagsScreenReaderText().exists()).toBe(false);
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
});
