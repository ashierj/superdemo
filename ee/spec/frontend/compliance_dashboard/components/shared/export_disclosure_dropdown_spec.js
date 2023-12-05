import { GlFormInput, GlFormGroup } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ExportApp from 'ee/compliance_dashboard/components/shared/export_disclosure_dropdown.vue';

describe('ExportApp component', () => {
  let wrapper;

  const findExportButton = () => wrapper.findByText('Export');
  const findDefaultDropdownTitle = () =>
    wrapper.findByText('Send email of the chosen report as CSV');
  const findViolationsExportButton = () => wrapper.findByText('Export violations report');
  const findProjectFrameworksButton = () => wrapper.findByText('Export list of project frameworks');
  const findChainOfCustodyReportButton = () => wrapper.findByText('Export chain of custody report');
  const findCustodyReportByCommmitButton = () =>
    wrapper.findByText('Export custody report of a specific commit');
  const findCustodyReportByCommitExportButton = () =>
    wrapper.findComponent('[data-testid="merge-commit-submit-button"]');
  const findCustodyReportByCommitCancelButton = () => wrapper.findByText('Cancel');
  const findCommitInput = () => wrapper.findComponent(GlFormInput);
  const findCommitInputGroup = () => wrapper.findComponent(GlFormGroup);

  const createComponent = ({ props = {}, data = {} }) => {
    return mountExtended(ExportApp, {
      propsData: {
        ...props,
      },
      data: () => data,
    });
  };

  describe('default behavior', () => {
    it('renders the dropdown button, content', () => {
      wrapper = createComponent({});

      expect(findExportButton().exists()).toBe(true);
      expect(findDefaultDropdownTitle().exists()).toBe(true);
      expect(findCustodyReportByCommmitButton().exists()).toBe(false);
    });
  });

  describe('when no export paths props are passed in', () => {
    it('renders no export buttons when no export paths are passed', () => {
      wrapper = createComponent({});

      expect(findViolationsExportButton().exists()).toBe(false);
      expect(findProjectFrameworksButton().exists()).toBe(false);
      expect(findChainOfCustodyReportButton().exists()).toBe(false);
    });
  });

  describe('when violations export path is passed in', () => {
    it('renders the violations export button', () => {
      wrapper = createComponent({ props: { violationsCsvExportPath: 'example-path' } });

      expect(findViolationsExportButton().exists()).toBe(true);
    });
  });

  describe('when project frameworks export path is passed in', () => {
    it('renders the project frameworks export button', () => {
      wrapper = createComponent({ props: { frameworksCsvExportPath: 'example-path' } });

      expect(findProjectFrameworksButton().exists()).toBe(true);
    });
  });

  describe('when chain of custody export path is passed in', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { mergeCommitsCsvExportPath: 'example-path' } });
    });

    it('renders the chain of custody export buttons', () => {
      expect(findChainOfCustodyReportButton().exists()).toBe(true);
      expect(findCustodyReportByCommmitButton().exists()).toBe(true);
    });

    describe('when chain of custody report of a specific commit is clicked', () => {
      beforeEach(async () => {
        await findCustodyReportByCommmitButton().trigger('click');
      });

      it('changes the title and content of the dropdown disclosure', () => {
        expect(findDefaultDropdownTitle().exists()).toBe(false);
        expect(findCustodyReportByCommmitButton().exists()).toBe(true);
        expect(findCommitInputGroup().exists()).toBe(true);
        expect(findCustodyReportByCommitExportButton().exists()).toBe(true);
        expect(findCustodyReportByCommitCancelButton().exists()).toBe(true);
      });

      it('sets the placeholder', () => {
        expect(findCommitInput().attributes('placeholder')).toEqual('Example: 2dc6aa3');
      });

      describe('when the cancel button is clicked', () => {
        beforeEach(async () => {
          await findCustodyReportByCommitCancelButton().trigger('click');
        });

        it('changes the title and content of the dropdown discloure back to default', () => {
          expect(findDefaultDropdownTitle().exists()).toBe(true);
          expect(findCustodyReportByCommmitButton().exists()).toBe(true);
          expect(findCommitInputGroup().exists()).toBe(false);
          expect(findCustodyReportByCommitExportButton().exists()).toBe(false);
          expect(findCustodyReportByCommitCancelButton().exists()).toBe(false);
        });
      });

      describe('when the commit input is valid', () => {
        beforeEach(async () => {
          wrapper = createComponent({
            props: { mergeCommitsCsvExportPath: 'example-path' },
            data: { validMergeCommitHash: true },
          });

          await findCustodyReportByCommmitButton().trigger('click');
        });

        it('shows that the input is valid', () => {
          expect(findCommitInputGroup().classes('is-invalid')).toBe(false);
        });

        it('enables the submit button', () => {
          expect(findCustodyReportByCommitExportButton().props('disabled')).toBe(false);
        });
      });

      describe('when the commit input is invalid', () => {
        beforeEach(async () => {
          wrapper = createComponent({
            props: { mergeCommitsCsvExportPath: 'example-path' },
            data: { validMergeCommitHash: false },
          });

          await findCustodyReportByCommmitButton().trigger('click');
        });

        it('shows that the input is invalid', () => {
          expect(findCommitInputGroup().classes('is-invalid')).toBe(true);
        });

        it('disables the submit button', () => {
          expect(findCustodyReportByCommitExportButton().props('disabled')).toBe(true);
        });
      });
    });
  });
});
