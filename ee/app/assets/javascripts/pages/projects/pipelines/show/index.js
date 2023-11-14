import initCCValidationRequiredAlert from 'ee/credit_card_validation_required_alert';
import initPipelines from '~/pages/projects/pipelines/init_pipelines';
import initPipelineDetails from '~/ci/pipeline_details/pipeline_details_bundle';
import initCodequalityReport from './codequality_report';
import initLicenseReport from './license_report';

initPipelines();
initPipelineDetails();
initLicenseReport();
initCodequalityReport();
initCCValidationRequiredAlert();
