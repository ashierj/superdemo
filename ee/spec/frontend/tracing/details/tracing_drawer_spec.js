import { GlDrawer } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingDrawer from 'ee/tracing/details/tracing_drawer.vue';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

jest.mock('~/lib/utils/dom_utils');

describe('TracingDrawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);

  const mockSpan = {
    service_name: 'test-service',
    operation: 'test-operation',
    emptyVal: '',
    span_attributes: {
      'http.status_code': '200',
      'http.method': 'GET',
      'http.empty': '',
    },
    resource_attributes: {
      'k8s.namespace.name': 'otel-demo-app',
      'k8s.deployment.name': 'otel-demo-loadgenerator',
      'k8s.deployment.empty': '',
    },
  };

  const mountComponent = ({ open = true, span = mockSpan } = {}) => {
    wrapper = shallowMountExtended(TracingDrawer, {
      propsData: {
        span,
        open,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  it('renders the component properly', () => {
    expect(wrapper.exists()).toBe(true);
    expect(findDrawer().exists()).toBe(true);
    expect(findDrawer().props('open')).toBe(true);
  });

  it('emits close', () => {
    findDrawer().vm.$emit('close');
    expect(wrapper.emitted('close').length).toBe(1);
  });

  it('displays the correct title', () => {
    expect(wrapper.findByTestId('drawer-title').text()).toBe('test-service : test-operation');
  });

  const findSection = (sectionId) => {
    const section = wrapper.findByTestId(sectionId);
    const title = section.find('[data-testid="section-title"]').text();
    const lines = section.findAll('[data-testid="section-line"]').wrappers.map((w) => ({
      name: w.find('[data-testid="section-line-name"]').text(),
      value: w.find('[data-testid="section-line-value"]').text(),
    }));
    return {
      title,
      lines,
    };
  };

  it.each([
    [
      'section-span-details',
      'Metadata',
      [
        { name: 'operation', value: 'test-operation' },
        { name: 'service_name', value: 'test-service' },
      ],
    ],
    [
      'section-span-attributes',
      'Attributes',
      [
        { name: 'http.method', value: 'GET' },
        { name: 'http.status_code', value: '200' },
      ],
    ],
    [
      'section-resource-attributes',
      'Resource attributes',
      [
        { name: 'k8s.deployment.name', value: 'otel-demo-loadgenerator' },
        { name: 'k8s.namespace.name', value: 'otel-demo-app' },
      ],
    ],
  ])('displays the %s section in expected order', (sectionId, expectedTitle, expectedLines) => {
    const { title, lines } = findSection(sectionId);
    expect(title).toBe(expectedTitle);
    expect(lines).toEqual(expectedLines);
  });

  it.each([
    ['span_attributes', 'section-span-attributes'],
    ['resource_attributes', 'section-resource-attributes'],
  ])('if %s is missing, it does not render %s', (attrKey, sectionId) => {
    mountComponent({ span: { ...mockSpan, [attrKey]: undefined } });
    expect(wrapper.findByTestId(sectionId).exists()).toBe(false);
  });

  describe('with no span', () => {
    beforeEach(() => {
      mountComponent({ span: null });
    });

    it('displays an empty title', () => {
      expect(wrapper.findByTestId('drawer-title').text()).toBe('');
    });

    it('does not render any section', () => {
      expect(wrapper.findByTestId('section-span-details').exists()).toBe(false);
      expect(wrapper.findByTestId('section-span-attributes').exists()).toBe(false);
      expect(wrapper.findByTestId('section-resource-attributes').exists()).toBe(false);
    });
  });

  describe('header height', () => {
    beforeEach(() => {
      getContentWrapperHeight.mockClear();
      getContentWrapperHeight.mockReturnValue(`1234px`);
    });

    it('does not set the header height if not open', () => {
      mountComponent({ open: false });

      expect(findDrawer().props('headerHeight')).toBe('0');
      expect(getContentWrapperHeight).not.toHaveBeenCalled();
    });

    it('sets the header height to match contentWrapperHeight if open', async () => {
      mountComponent({ open: true });
      await nextTick();

      expect(findDrawer().props('headerHeight')).toBe('1234px');
      expect(getContentWrapperHeight).toHaveBeenCalled();
    });
  });
});
