import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_COMPLIANCE_FRAMEWORK } from '~/graphql_shared/constants';

export const projectScanExecutionPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: '3',
        __typename: 'Project',
        scanExecutionPolicies: {
          nodes,
        },
      },
    },
  });

export const groupScanExecutionPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: '3',
        __typename: 'Group',
        scanExecutionPolicies: {
          nodes,
        },
      },
    },
  });

export const projectScanResultPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: '3',
        __typename: 'Project',
        scanResultPolicies: {
          nodes,
        },
      },
    },
  });

export const groupScanResultPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: '3',
        __typename: 'Group',
        scanResultPolicies: {
          nodes,
        },
      },
    },
  });

export const mockLinkSecurityPolicyProjectResponses = {
  success: jest.fn().mockResolvedValue({ data: { securityPolicyProjectAssign: { errors: [] } } }),
  failure: jest
    .fn()
    .mockResolvedValue({ data: { securityPolicyProjectAssign: { errors: ['link failed'] } } }),
};

export const mockUnlinkSecurityPolicyProjectResponses = {
  success: jest.fn().mockResolvedValue({ data: { securityPolicyProjectUnassign: { errors: [] } } }),
  failure: jest.fn().mockResolvedValue({
    data: { securityPolicyProjectUnassign: { errors: ['unlink failed'] } },
  }),
};

export const complianceFrameworksResponse = [
  {
    id: convertToGraphQLId(TYPE_COMPLIANCE_FRAMEWORK, 1),
    name: 'A1',
    default: true,
    description: 'description 1',
    color: '#cd5b45',
    pipelineConfigurationFullPath: 'path 1',
    projects: { nodes: [] },
  },
  {
    id: convertToGraphQLId(TYPE_COMPLIANCE_FRAMEWORK, 2),
    name: 'B2',
    default: false,
    description: 'description 2',
    color: '#cd5b45',
    pipelineConfigurationFullPath: 'path 2',
    projects: {
      nodes: [
        {
          id: '1',
          name: 'project-1',
        },
      ],
    },
  },
  {
    id: convertToGraphQLId(TYPE_COMPLIANCE_FRAMEWORK, 3),
    name: 'a3',
    default: true,
    description: 'description 3',
    color: '#cd5b45',
    pipelineConfigurationFullPath: 'path 3',
    projects: {
      nodes: [
        {
          id: '1',
          name: 'project-1',
        },
        {
          id: '2',
          name: 'project-2',
        },
      ],
    },
  },
];
