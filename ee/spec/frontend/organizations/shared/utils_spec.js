import {
  renderProjectDeleteSuccessToast as renderProjectDeleteSuccessToastCE,
  deleteProjectParams as deleteProjectParamsCE,
} from '~/organizations/shared/utils';
import {
  deleteProjectParams,
  renderProjectDeleteSuccessToast,
} from 'ee/organizations/shared/utils';
import toast from '~/vue_shared/plugins/global_toast';

const MOCK_CE_PARAMS = { ceParam: true };

jest.mock('~/organizations/shared/utils', () => ({
  ...jest.requireActual('~/organizations/shared/utils'),
  renderProjectDeleteSuccessToast: jest.fn(),
  deleteProjectParams: jest.fn(() => MOCK_CE_PARAMS),
}));
jest.mock('~/vue_shared/plugins/global_toast');

const MOCK_PROJECT_NO_DELAY_DELETION = {
  name: 'No Delay Project',
  fullPath: 'path/to/project/1',
  isAdjournedDeletionEnabled: false,
  markedForDeletionOn: null,
  permanentDeletionDate: null,
};

const MOCK_PROJECT_WITH_DELAY_DELETION = {
  name: 'With Delay Project',
  fullPath: 'path/to/project/2',
  isAdjournedDeletionEnabled: true,
  markedForDeletionOn: null,
  permanentDeletionDate: '2024-03-31',
};

const MOCK_PROJECT_PENDING_DELETION = {
  name: 'Pending Deletion Project',
  fullPath: 'path/to/project/3',
  isAdjournedDeletionEnabled: true,
  markedForDeletionOn: '2024-03-24',
  permanentDeletionDate: '2024-03-31',
};

describe('renderProjectDeleteSuccessToast', () => {
  it('when delayed deletion is disabled, calls renderProjectDeleteSuccessToastCE', () => {
    renderProjectDeleteSuccessToast(MOCK_PROJECT_NO_DELAY_DELETION);

    expect(renderProjectDeleteSuccessToastCE).toHaveBeenCalledWith(MOCK_PROJECT_NO_DELAY_DELETION);
    expect(toast).not.toHaveBeenCalled();
  });

  it('when delayed deletion is enabled and project is not pending deletion, calls toast with pending deletion info', () => {
    renderProjectDeleteSuccessToast(MOCK_PROJECT_WITH_DELAY_DELETION);

    expect(renderProjectDeleteSuccessToastCE).not.toHaveBeenCalled();
    expect(toast).toHaveBeenCalledWith(
      `Project '${MOCK_PROJECT_WITH_DELAY_DELETION.name}' will be deleted on ${MOCK_PROJECT_WITH_DELAY_DELETION.permanentDeletionDate}.`,
    );
  });

  it('when delayed deletion is enabled and project is already pending deletion, calls renderProjectDeleteSuccessToastCE', () => {
    renderProjectDeleteSuccessToast(MOCK_PROJECT_PENDING_DELETION);

    expect(renderProjectDeleteSuccessToastCE).toHaveBeenCalledWith(MOCK_PROJECT_PENDING_DELETION);
    expect(toast).not.toHaveBeenCalled();
  });
});

describe('deleteProjectParams', () => {
  it('when delayed deletion is disabled, returns deleteProjectParamsCE', () => {
    const res = deleteProjectParams(MOCK_PROJECT_NO_DELAY_DELETION);

    expect(deleteProjectParamsCE).toHaveBeenCalled();
    expect(res).toStrictEqual(MOCK_CE_PARAMS);
  });

  it('when delayed deletion is enabled and project is not pending deletion, returns deleteProjectParamsCE', () => {
    const res = deleteProjectParams(MOCK_PROJECT_WITH_DELAY_DELETION);

    expect(deleteProjectParamsCE).toHaveBeenCalled();
    expect(res).toStrictEqual(MOCK_CE_PARAMS);
  });

  it('when delayed deletion is enabled and project is already pending deletion, returns permanent deletion params', () => {
    const res = deleteProjectParams(MOCK_PROJECT_PENDING_DELETION);

    expect(deleteProjectParamsCE).not.toHaveBeenCalled();
    expect(res).toStrictEqual({
      permanently_remove: true,
      full_path: MOCK_PROJECT_PENDING_DELETION.fullPath,
    });
  });
});
