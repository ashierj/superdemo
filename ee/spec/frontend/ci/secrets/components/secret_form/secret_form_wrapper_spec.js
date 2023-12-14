import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SecretFormWrapper from 'ee/ci/secrets/components/secret_form/secret_form_wrapper.vue';
import SecretForm from 'ee/ci/secrets/components/secret_form/secret_form.vue';

describe('SecretFormWrapper component', () => {
  let wrapper;

  const findPageTitle = () => wrapper.find('h1').text();
  const findSecretForm = () => wrapper.findComponent(SecretForm);

  const createComponent = (props) => {
    wrapper = shallowMountExtended(SecretFormWrapper, {
      propsData: {
        secretKey: 'group_secret_1',
        ...props,
      },
    });
  };

  it('shows new secret form when creating', () => {
    createComponent({ isEditing: false });

    expect(findPageTitle()).toBe('New secret');
    expect(findSecretForm().props('submitButtonText')).toBe('Add secret');
  });

  it('shows secret edit form when editing', () => {
    createComponent({ isEditing: true });

    expect(findPageTitle()).toBe(`Edit group_secret_1`);
    expect(findSecretForm().props('submitButtonText')).toBe('Save changes');
  });
});
