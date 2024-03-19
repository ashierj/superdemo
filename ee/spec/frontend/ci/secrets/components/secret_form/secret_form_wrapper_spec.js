import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ENTITY_GROUP } from 'ee/ci/secrets/constants';
import SecretFormWrapper from 'ee/ci/secrets/components/secret_form/secret_form_wrapper.vue';

Vue.use(VueApollo);

describe('SecretFormWrapper component', () => {
  let wrapper;

  const defaultProps = {
    entity: ENTITY_GROUP,
    fullPath: 'full/path/to/entity',
    isEditing: false,
    secretKey: 'group_secret_1',
  };

  const findPageTitle = () => wrapper.find('h1').text();

  const createComponent = ({ props, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(SecretFormWrapper, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('template', () => {
    it('shows new secret form when creating', () => {
      createComponent({ props: { isEditing: false } });

      expect(findPageTitle()).toBe('New secret');
    });

    it('shows edit form when editing', () => {
      createComponent({ props: { isEditing: true } });

      expect(findPageTitle()).toBe(`Edit group_secret_1`);
    });
  });
});
