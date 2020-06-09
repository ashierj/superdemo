import EpicsSelect from 'ee/vue_shared/components/sidebar/epics_select/epics_select_bundle';
import WeightSelect from 'ee/weight_select';
import initForm from '~/pages/projects/issues/form';

export default () => {
  // eslint-disable-next-line no-new
  new EpicsSelect();
  // eslint-disable-next-line no-new
  new WeightSelect();
  initForm();
};
