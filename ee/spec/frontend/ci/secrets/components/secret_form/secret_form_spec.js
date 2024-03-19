import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlDatepicker, GlFormTextarea } from '@gitlab/ui';
import { getDateInFuture } from '~/lib/utils/datetime_utility';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import CiEnvironmentsDropdown from '~/ci/common/private/ci_environments_dropdown';
import { DETAILS_ROUTE_NAME } from 'ee/ci/secrets/constants';
import SecretForm from 'ee/ci/secrets/components/secret_form/secret_form.vue';
import SecretPreviewModal from 'ee/ci/secrets/components/secret_form/secret_preview_modal.vue';

describe('SecretForm component', () => {
  let wrapper;

  const defaultProps = {
    areEnvironmentsLoading: false,
    environments: ['production', 'development'],
    isEditing: false,
    redirectToRouteName: DETAILS_ROUTE_NAME,
    submitButtonText: 'Add secret',
  };

  const findAddCronButton = () => wrapper.findByTestId('add-custom-rotation-button');
  const findCronField = () => wrapper.findByTestId('secret-cron');
  const findDescriptionField = () => wrapper.findByTestId('secret-description');
  const findExpirationField = () => wrapper.findComponent(GlDatepicker);
  const findEnvironmentsDropdown = () => wrapper.findComponent(CiEnvironmentsDropdown);
  const findKeyField = () => wrapper.findByTestId('secret-key');
  const findPreviewModal = () => wrapper.findComponent(SecretPreviewModal);
  const findRotationPeriodField = () => wrapper.findComponent(GlCollapsibleListbox);
  const findValueField = () => wrapper.findComponent(GlFormTextarea);
  const findSubmitButton = () => wrapper.findByTestId('submit-form-button');

  const createComponent = ({ props, mountFn = shallowMountExtended, stubs } = {}) => {
    wrapper = mountFn(SecretForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs,
    });
  };

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders all fields', () => {
      expect(findDescriptionField().exists()).toBe(true);
      expect(findExpirationField().exists()).toBe(true);
      expect(findEnvironmentsDropdown().exists()).toBe(true);
      expect(findKeyField().exists()).toBe(true);
      expect(findRotationPeriodField().exists()).toBe(true);
      expect(findValueField().exists()).toBe(true);
    });

    it('does not show preview modal by default', () => {
      expect(findPreviewModal().props('isVisible')).toBe(false);
    });

    it('sets expiration date in the future', () => {
      const today = new Date();
      const expirationMinDate = findExpirationField().props('minDate').getTime();
      expect(expirationMinDate).toBeGreaterThan(today.getTime());
    });
  });

  describe('rotation period field', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows default toggle text', () => {
      expect(findRotationPeriodField().props('toggleText')).toBe('Select a rotation interval');
    });

    it('can select predefined rotation periods and renders the correct toggle text', async () => {
      findRotationPeriodField().vm.$emit('click');
      findRotationPeriodField().vm.$emit('select', '14');

      await nextTick();

      expect(findRotationPeriodField().props('toggleText')).toBe('Every 2 weeks');
    });

    it('can set custom cron', async () => {
      findRotationPeriodField().vm.$emit('click');
      findCronField().vm.$emit('input', '0 6 * * *');
      findAddCronButton().vm.$emit('click');

      await nextTick();

      expect(findRotationPeriodField().props('toggleText')).toBe('0 6 * * *');
    });
  });

  describe('preview modal', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('submit button opens preview modal', async () => {
      expect(findPreviewModal().props('isVisible')).toBe(false);

      findSubmitButton().vm.$emit('click');
      await nextTick();

      expect(findPreviewModal().props('isVisible')).toBe(true);
    });

    it('passes the correct props', async () => {
      findKeyField().vm.$emit('input', 'SECRET_KEY');
      findDescriptionField().vm.$emit('input', 'This is a secret.');

      const today = new Date();
      const expirationDate = getDateInFuture(today, 1);
      findExpirationField().vm.$emit('input', { endDate: '' });
      findExpirationField().vm.$emit('input', expirationDate);

      findRotationPeriodField().vm.$emit('click');
      findCronField().vm.$emit('input', '0 6 * * *');
      findAddCronButton().vm.$emit('click');

      findSubmitButton().vm.$emit('click');
      await nextTick();

      expect(findPreviewModal().props()).toMatchObject({
        description: 'This is a secret.',
        expiration: expirationDate,
        isEditing: defaultProps.isEditing,
        rotationPeriod: '0 6 * * *',
        secretKey: 'SECRET_KEY',
      });
    });

    it('hides modal when hide-preview-modal event is emitted', async () => {
      findSubmitButton().vm.$emit('click');
      await nextTick();

      expect(findPreviewModal().props('isVisible')).toBe(true);

      await findPreviewModal().vm.$emit('hide-preview-modal');

      expect(findPreviewModal().props('isVisible')).toBe(false);
    });
  });
});
