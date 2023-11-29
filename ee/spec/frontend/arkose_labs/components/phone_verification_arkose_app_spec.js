import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PhoneVerificationArkoseApp from 'ee/arkose_labs/components/phone_verification_arkose_app.vue';
import { initArkoseLabsScript } from 'ee/arkose_labs/init_arkose_labs_script';

jest.mock('ee/arkose_labs/init_arkose_labs_script');
let onShown;
let onCompleted;
const mockResetHandler = jest.fn();

initArkoseLabsScript.mockImplementation(() => ({
  setConfig: ({ onShown: shownHandler, onCompleted: completedHandler }) => {
    onShown = shownHandler;
    onCompleted = completedHandler;
  },
  reset: mockResetHandler,
}));

const MOCK_ARKOSE_RESPONSE = { token: 'verification-token' };
const MOCK_PUBLIC_KEY = 'arkose-labs-public-api-key';
const MOCK_DOMAIN = 'client-api.arkoselabs.com';

describe('PhoneVerificationArkoseApp', () => {
  let wrapper;

  const findChallengeContainer = () => wrapper.findByTestId('arkose-labs-challenge');

  const createComponent = () => {
    wrapper = mountExtended(PhoneVerificationArkoseApp, {
      propsData: {
        publicKey: MOCK_PUBLIC_KEY,
        domain: MOCK_DOMAIN,
        resetSession: false,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should initialise the arkose labs script', () => {
    expect(initArkoseLabsScript).toHaveBeenCalledWith({
      publicKey: MOCK_PUBLIC_KEY,
      domain: MOCK_DOMAIN,
    });
  });

  it('should show the challenge container when arkose script calls `onShown`', async () => {
    expect(findChallengeContainer().isVisible()).toBe(false);

    onShown();
    await nextTick();

    expect(findChallengeContainer().isVisible()).toBe(true);
  });

  it('should emit `challenge-solved` event when arkose challenge is solved', async () => {
    onShown();
    onCompleted(MOCK_ARKOSE_RESPONSE);

    await nextTick();

    expect(wrapper.emitted('challenge-solved')).toStrictEqual([[MOCK_ARKOSE_RESPONSE.token]]);
  });

  it('should call reset when resetSession is set to true', async () => {
    // setProps is justified here because we are testing the component's
    // reactive behavior which constitutes an exception
    // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state

    await wrapper.setProps({
      resetSession: true,
    });

    expect(mockResetHandler).toHaveBeenCalled();
  });
});
