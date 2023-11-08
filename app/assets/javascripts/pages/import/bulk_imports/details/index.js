import Vue from 'vue';
import BulkImportDetailsApp from '~/import/details/components/bulk_import_details_app.vue';

export const initBulkImportDetails = () => {
  const el = document.querySelector('.js-bulk-import-details');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'BulkImportDetailsRoot',
    render(createElement) {
      return createElement(BulkImportDetailsApp);
    },
  });
};

initBulkImportDetails();
