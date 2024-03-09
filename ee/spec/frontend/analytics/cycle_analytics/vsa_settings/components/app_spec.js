import { shallowMount } from '@vue/test-utils';
import VSASettingsApp from 'ee/analytics/cycle_analytics/vsa_settings/components/app.vue';
import ValueStreamForm from 'ee/analytics/cycle_analytics/vsa_settings/components/value_stream_form.vue';

describe('Value stream analytics settings app component', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(VSASettingsApp, {
      propsData: {
        isEditPage: false,
        ...props,
      },
    });
  };

  const findValueStreamForm = () => wrapper.findComponent(ValueStreamForm);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the value stream form component', () => {
      expect(findValueStreamForm().props()).toMatchObject({
        isEditing: false,
      });
    });
  });

  describe('isEditPage=true', () => {
    beforeEach(() => {
      createComponent({ props: { isEditPage: true } });
    });

    it(`enables the value stream form component's editing state`, () => {
      expect(findValueStreamForm().props('isEditing')).toBe(true);
    });
  });
});
