import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const i18n = {
  basicInformation: s__('ComplianceFrameworks|Basic information'),
  basicInformationDetails: s__('ComplianceFrameworks|Name, description'),

  addFrameworkTitle: s__('ComplianceFrameworks|Create a compliance framework'),
  editFrameworkTitle: s__('ComplianceFrameworks|Edit a compliance framework'),

  submitButtonText: s__('ComplianceFrameworks|Add framework'),

  successMessageText: s__('ComplianceFrameworks|Compliance framework created'),
  titleInputLabel: s__('ComplianceFrameworks|Name'),
  titleInputInvalid: s__('ComplianceFrameworks|Name is required'),
  descriptionInputLabel: s__('ComplianceFrameworks|Description'),
  descriptionInputInvalid: s__('ComplianceFrameworks|Description is required'),
  pipelineConfigurationInputLabel: s__(
    'ComplianceFrameworks|Compliance pipeline configuration (optional)',
  ),
  pipelineConfigurationInputDescription: s__(
    'ComplianceFrameworks|Required format: %{codeStart}path/file.y[a]ml@group-name/project-name%{codeEnd}. %{linkStart}See some examples%{linkEnd}.',
  ),
  pipelineConfigurationInputDisabledPopoverTitle: s__(
    'ComplianceFrameworks|Requires Ultimate subscription',
  ),
  pipelineConfigurationInputDisabledPopoverContent: s__(
    'ComplianceFrameworks|Set compliance pipeline configuration for projects that use this framework. %{linkStart}How do I create the configuration?%{linkEnd}',
  ),
  pipelineConfigurationInputDisabledPopoverLink: helpPagePath(
    'user/group/compliance_frameworks.html#compliance-pipelines',
  ),
  pipelineConfigurationInputInvalidFormat: s__('ComplianceFrameworks|Invalid format'),
  pipelineConfigurationInputUnknownFile: s__('ComplianceFrameworks|Configuration not found'),
  colorInputLabel: s__('ComplianceFrameworks|Background color'),

  editSaveBtnText: __('Save changes'),
  addSaveBtnText: s__('ComplianceFrameworks|Add framework'),
  fetchError: s__(
    'ComplianceFrameworks|Error fetching compliance frameworks data. Please refresh the page or try a different framework',
  ),

  setAsDefault: s__('ComplianceFrameworks|Set as default'),
  setAsDefaultDetails: s__(
    'ComplianceFrameworks|Default framework will be applied automatically to any new project created in the group or sub group.',
  ),
  setAsDefaultOnlyOne: s__('ComplianceFrameworks|There can be only one default framework.'),
};
