export const shouldHandRaiseLeadMount = async () => {
  const elements = document.querySelectorAll('.js-hand-raise-lead-button');
  if (elements.length > 0) {
    const { initHandRaiseLead } = await import(
      /* webpackChunkName: 'init_hand_raise_lead' */ './init_hand_raise_lead'
    );

    elements.forEach(async (el) => {
      initHandRaiseLead(el);
    });
  }
};
