import Vue from 'vue';
import { mount } from '@vue/test-utils';
import CustomStageForm from 'ee/analytics/cycle_analytics/components/custom_stage_form.vue';
import { mockLabels } from '../../../../../../spec/javascripts/vue_shared/components/sidebar/labels_select/mock_data';
import { apiResponse, rawEvents } from '../mock_data';

const labels = mockLabels.map(({ title, ...rest }) => ({ ...rest, name: title }));

const { events } = apiResponse;

const startEvents = events.filter(ev => ev.canBeStartEvent);
const stopEvents = events.filter(ev => !ev.canBeStartEvent);

const initData = {
  name: 'Cool stage pre',
  startEvent: 'issue_label_added',
  startEventLabel: labels[0].id,
  stopEvent: 'issue_label_removed',
  stopEventLabel: labels[1].id,
};

describe('CustomStageForm', () => {
  function createComponent(props) {
    return mount(CustomStageForm, {
      propsData: {
        events,
        labels,
        ...props,
      },
      sync: false,
    });
  }

  let wrapper = null;

  const sel = {
    name: '[name="add-stage-name"]',
    startEvent: '[name="add-stage-start-event"]',
    startEventLabel: '[name="add-stage-start-event-label"]',
    stopEvent: '[name="add-stage-stop-event"]',
    stopEventLabel: '[name="add-stage-stop-event-label"]',
    submit: '.js-add-stage',
    cancel: '.js-add-stage-cancel',
    invalidFeedback: '.invalid-feedback',
  };

  function selectDropdownOption(_wrapper, dropdown, index) {
    _wrapper
      .find(dropdown)
      .findAll('option')
      .at(index)
      .setSelected();
  }

  describe('Empty form', () => {
    beforeEach(() => {
      wrapper = createComponent({}, false);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe.each([
      ['Name', sel.name, true],
      ['Start event', sel.startEvent, true],
      ['Stop event', sel.stopEvent, false],
      ['Submit', sel.submit, false],
      ['Cancel', sel.cancel, false],
    ])('by default', (field, $sel, enabledState) => {
      const state = enabledState ? 'enabled' : 'disabled';
      it(`field '${field}' is ${state}`, () => {
        const el = wrapper.find($sel);
        expect(el.exists()).toEqual(true);
        if (!enabledState) {
          expect(el.attributes('disabled')).toEqual('disabled');
        } else {
          expect(el.attributes('disabled')).toBeUndefined();
        }
      });
    });

    describe('Start event', () => {
      describe('with events', () => {
        beforeEach(() => {
          wrapper = createComponent({}, false);
        });
        afterEach(() => {
          wrapper.destroy();
        });
        it('selects events with canBeStartEvent=true for the start events dropdown', () => {
          const select = wrapper.find(sel.startEvent);
          startEvents.forEach(ev => {
            expect(select.html()).toHaveHtml(
              `<option value="${ev.identifier}">${ev.name}</option>`,
            );
          });
          stopEvents.forEach(ev => {
            expect(select.html()).not.toHaveHtml(
              `<option value="${ev.identifier}">${ev.name}</option>`,
            );
          });
        });

        it('will exclude stop events for the dropdown', () => {
          const select = wrapper.find(sel.startEvent);
          stopEvents.forEach(ev => {
            expect(select.html()).not.toHaveHtml(
              `<option value="${ev.identifier}">${ev.name}</option>`,
            );
          });
        });
      });

      describe('start event label', () => {
        beforeEach(() => {
          wrapper = createComponent({}, false);
        });

        afterEach(() => {
          wrapper.destroy();
        });
        it('is hidden by default', () => {
          expect(wrapper.find(sel.startEventLabel).exists()).toEqual(false);
        });

        it('will display the start event label field if a label event is selected', () => {
          wrapper.setData({
            fields: {
              startEvent: 'issue_label_added',
            },
          });

          Vue.nextTick(() => {
            expect(wrapper.find(sel.startEventLabel).exists()).toEqual(true);
          });
        });

        it('will set the "startEventLabel" field when selected', () => {
          const selectedLabelId = labels[0].id;
          expect(wrapper.vm.fields.startEventLabel).toEqual(null);

          wrapper.find(sel.startEvent).setValue('issue_label_added');
          Vue.nextTick(() => {
            wrapper
              .find(sel.startEventLabel)
              .findAll('.dropdown-item')
              .at(1) // item at index 0 is 'select a label'
              .trigger('click');

            Vue.nextTick(() => {
              expect(wrapper.vm.fields.startEventLabel).toEqual(selectedLabelId);
            });
          });
        });
      });
    });
    describe('Stop event', () => {
      beforeEach(() => {
        wrapper = createComponent(
          {
            events: rawEvents,
          },
          false,
        );
      });

      it('notifies that a start event needs to be selected first', () => {
        expect(wrapper.text()).toContain('Please select a start event first');
      });

      it('clears notification when a start event is selected', () => {
        selectDropdownOption(wrapper, sel.startEvent, 1);
        Vue.nextTick(() =>
          expect(wrapper.text()).not.toContain('Please select a start event first'),
        );
      });

      it('is enabled when a start event is selected', () => {
        const el = wrapper.find(sel.stopEvent);
        expect(el.attributes('disabled')).toEqual('disabled');

        selectDropdownOption(wrapper, sel.startEvent, 1);
        Vue.nextTick(() => expect(el.attributes('disabled')).toBeUndefined());
      });

      it('will update the list of stop events when a start event is changed', () => {
        let stopOptions = wrapper.find(sel.stopEvent).findAll('option');
        expect(stopOptions.length).toEqual(1);

        selectDropdownOption(wrapper, sel.startEvent, 1);

        Vue.nextTick(() => {
          stopOptions = wrapper.find(sel.stopEvent).findAll('option');
          expect(stopOptions.length).toEqual(3);
        });
      });

      it('will only display valid stop events allowed for the selected start event', () => {
        let stopOptions = wrapper.find(sel.stopEvent).findAll('option');
        expect(stopOptions.at(0).html()).toEqual('<option value="">Select stop event</option>');

        selectDropdownOption(wrapper, sel.startEvent, 1);

        Vue.nextTick(() => {
          stopOptions = wrapper.find(sel.stopEvent).findAll('option');
          [
            { name: 'Select stop event', identifier: '' },
            { name: 'Issue closed', identifier: 'issue_closed' },
            { name: 'Issue merged', identifier: 'issue_merged' },
          ].forEach(({ name, identifier }, i) => {
            expect(stopOptions.at(i).html()).toEqual(
              `<option value="${identifier}">${name}</option>`,
            );
          });

          [
            { name: 'Issue created', identifier: 'issue_created' },
            { name: 'Merge request closed', identifier: 'merge_request_closed' },
          ].forEach(({ name, identifier }) => {
            expect(wrapper.find(sel.stopEvent).html()).not.toHaveHtml(
              `<option value="${identifier}">${name}</option>`,
            );
          });
        });
      });

      describe('with a stop event selected and a change to the start event', () => {
        beforeEach(() => {
          wrapper = createComponent({}, false);

          wrapper.setData({
            fields: {
              name: 'Cool stage',
              startEvent: 'issue_created',
              startEventLabel: null,
              stopEvent: 'issue_stage_end',
              stopEventLabel: null,
            },
          });
        });

        afterEach(() => {
          wrapper.destroy();
        });

        it('will notify if the current start and stop event pair is not valid', () => {
          expect(wrapper.find(sel.invalidFeedback).exists()).toEqual(false);

          selectDropdownOption(wrapper, sel.startEvent, 2);

          Vue.nextTick(() => {
            expect(wrapper.find(sel.invalidFeedback).exists()).toEqual(true);
            expect(wrapper.find(sel.invalidFeedback).text()).toContain(
              'Start event changed, please select a valid stop event',
            );
          });
        });
        it('will update the list of stop events', () => {
          const se = wrapper.vm.stopEventOptions;
          selectDropdownOption(wrapper, sel.startEvent, 2);
          Vue.nextTick(() => {
            expect(se[1].value).not.toEqual(wrapper.vm.stopEventOptions[1].value);
          });
        });
        it('will disable the submit button until a valid stopEvent is selected', () => {
          selectDropdownOption(wrapper, sel.startEvent, 2);
          Vue.nextTick(() => {
            expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
          });
        });
      });

      describe('Stop event label', () => {
        beforeEach(() => {
          wrapper = createComponent({}, false);
        });

        afterEach(() => {
          wrapper.destroy();
        });
        it('is hidden by default', () => {
          expect(wrapper.find(sel.startEventLabel).exists()).toEqual(false);
        });
        it('will display the stop event label field if a label event is selected', () => {
          expect(wrapper.find(sel.stopEventLabel).exists()).toEqual(false);

          wrapper.setData({
            fields: {
              startEvent: 'issue_label_added',
              stopEvent: 'issue_label_removed',
            },
          });

          Vue.nextTick(() => {
            expect(wrapper.find(sel.stopEventLabel).exists()).toEqual(true);
          });
        });

        it('will set the "stopEventLabel" field when selected', () => {
          const selectedLabelId = labels[1].id;
          expect(wrapper.vm.fields.stopEventLabel).toEqual(null);

          wrapper.setData({
            fields: {
              startEvent: 'issue_label_added',
              stopEvent: 'issue_label_removed',
            },
          });

          Vue.nextTick(() => {
            wrapper
              .find(sel.stopEventLabel)
              .findAll('.dropdown-item')
              .at(2) // item at index 0 is 'select a label'
              .trigger('click');

            Vue.nextTick(() => {
              expect(wrapper.vm.fields.stopEventLabel).toEqual(selectedLabelId);
            });
          });
        });
      });
    });

    describe('Add stage button', () => {
      beforeEach(() => {
        wrapper = createComponent({}, false);

        selectDropdownOption(wrapper, sel.startEvent, 1);

        Vue.nextTick(() => {
          selectDropdownOption(wrapper, sel.stopEvent, 1);
        });
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('is enabled when all required fields are filled', () => {
        const btn = wrapper.find(sel.submit);

        expect(btn.attributes('disabled')).toEqual('disabled');
        wrapper.find(sel.name).setValue('Cool stage');

        Vue.nextTick(() => {
          expect(btn.attributes('disabled')).toBeUndefined();
        });
      });

      describe('with all fields set', () => {
        beforeEach(() => {
          wrapper = createComponent({}, false);

          selectDropdownOption(wrapper, sel.startEvent, 1);

          Vue.nextTick(() => {
            selectDropdownOption(wrapper, sel.stopEvent, 1);
            wrapper.find(sel.name).setValue('Cool stage');
          });
        });

        afterEach(() => {
          wrapper.destroy();
        });
        it('emits a `submit` event when clicked', () => {
          expect(wrapper.emitted().submit).toBeUndefined();

          wrapper.find(sel.submit).trigger('click');
          expect(wrapper.emitted().submit).toBeTruthy();
          expect(wrapper.emitted().submit.length).toEqual(1);
        });
        it('`submit` event receives the latest data', () => {
          expect(wrapper.emitted().submit).toBeUndefined();

          const res = [
            {
              name: 'Cool stage',
              startEvent: 'issue_created',
              startEventLabel: null,
              stopEvent: 'issue_stage_end',
              stopEventLabel: null,
            },
          ];

          wrapper.find(sel.submit).trigger('click');
          expect(wrapper.emitted().submit[0]).toEqual(res);
        });
      });
    });

    describe('Cancel button', () => {
      beforeEach(() => {
        wrapper = createComponent({}, false);
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('is enabled when the form is dirty', () => {
        const btn = wrapper.find(sel.cancel);

        expect(btn.attributes('disabled')).toEqual('disabled');
        wrapper.find(sel.name).setValue('Cool stage');

        Vue.nextTick(() => {
          expect(btn.attributes('disabled')).toBeUndefined();
        });
      });
      it('will reset the fields when clicked', () => {
        wrapper.setData({
          fields: {
            name: 'Cool stage pre',
            startEvent: 'issue_label_added',
            stopEvent: 'issue_label_removed',
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.cancel).trigger('click');

          Vue.nextTick(() => {
            expect(wrapper.vm.fields).toEqual({
              name: '',
              startEvent: '',
              startEventLabel: null,
              stopEvent: '',
              stopEventLabel: null,
            });
          });
        });
      });
      it('will emit the `cancel` event when clicked', () => {
        expect(wrapper.emitted().cancel).toBeUndefined();

        wrapper.setData({
          fields: {
            name: 'Cool stage pre',
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.cancel).trigger('click');

          Vue.nextTick(() => {
            expect(wrapper.emitted().cancel).toBeTruthy();
            expect(wrapper.emitted().cancel.length).toEqual(1);
          });
        });
      });
    });
  });

  describe('Prepopulated form', () => {
    beforeEach(() => {
      wrapper = createComponent(
        {
          initialFields: {
            ...initData,
          },
        },
        false,
      );

      wrapper.setData({
        fields: {
          ...initData,
        },
      });

      Vue.nextTick();
    });

    afterEach(() => {
      wrapper.destroy();
    });
    describe('Cancel button', () => {
      it('will reset the fields to initial state when clicked', () => {
        wrapper.setData({
          fields: {
            name: 'Cool stage pre',
            startEvent: 'issue_label_added',
            stopEvent: 'issue_label_removed',
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.cancel).trigger('click');

          Vue.nextTick(() => {
            expect(wrapper.vm.fields).toEqual({
              ...initData,
            });
          });
        });
      });
    });
    describe('Add stage button', () => {
      it('is disabled by default', () => {
        expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
      });
      it('is enabled when a field is changed and fields are valid', () => {
        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        Vue.nextTick(() => {
          expect(wrapper.find(sel.submit).attributes('disabled')).toBeUndefined();
        });
      });
      it('is disabled when a field is changed but fields are incomplete', () => {
        wrapper.setData({
          fields: {
            name: '',
          },
        });

        Vue.nextTick(() => {
          expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
        });
      });
      it('emits a `submit` event when clicked', () => {
        expect(wrapper.emitted().submit).toBeUndefined();

        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.submit).trigger('click');

          Vue.nextTick(() => {
            expect(wrapper.emitted().submit).toBeTruthy();
            expect(wrapper.emitted().submit.length).toEqual(1);
          });
        });
      });
      it('`submit` event receives the latest data', () => {
        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.submit).trigger('click');

          Vue.nextTick(() => {
            const submitted = wrapper.emitted().submit[0];
            expect(submitted).not.toEqual([initData]);
            expect(submitted).toEqual([{ ...initData, name: 'Cool updated form' }]);
          });
        });
      });
    });
  });
});
