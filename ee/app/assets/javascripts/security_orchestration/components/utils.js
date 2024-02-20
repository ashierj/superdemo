import { isEmpty } from 'lodash';
import {
  EXCLUDING,
  INCLUDING,
} from 'ee/security_orchestration/components/policy_editor/scope/constants';

export const isPolicyInherited = (source) => source?.inherited === true;

export const policyHasNamespace = (source) => Boolean(source?.namespace);

/**
 * @param policyScope policy scope object on security policy
 * @returns {Boolean}
 */
export const isDefaultMode = (policyScope) => {
  return policyScope === undefined || policyScope === null || isEmpty(policyScope);
};

/**
 * Returns true if police scope has projects that are excluded from it
 * @param policyScope policy scope object on security policy
 * @returns {boolean}
 */
export const policyScopeHasExcludingProjects = (policyScope = {}) => {
  const { projects: { excluding = [] } = {} } = policyScope || {};
  return Boolean(excluding) && excluding?.filter(Boolean).length > 0;
};

/**
 * Returns true if policy scope applies to specific projects
 * @param policyScope policy scope object on security policy
 * @returns {boolean}
 */
export const policyScopeHasIncludingProjects = (policyScope = {}) => {
  const { projects: { including = [] } = {} } = policyScope || {};
  return Boolean(including) && including?.filter(Boolean).length > 0;
};

/**
 * Based on existence excluding or including projects on policy scope
 * return appropriate key
 * @param policyScope policyScope policy scope object on security policy
 * @returns {string|INCLUDING|EXCLUDING}
 */
export const policyScopeProjectsKey = (policyScope = {}) => {
  return policyScopeHasIncludingProjects(policyScope) ? INCLUDING : EXCLUDING;
};

/**
 * Number of linked to policy scope projects
 * @param policyScope policyScope policy scope object on security policy
 * @returns {Number}
 */
export const policyScopeProjectLength = (policyScope = {}) => {
  return policyScope?.projects?.[policyScopeProjectsKey(policyScope)]?.filter(Boolean).length || 0;
};

/**
 * Check if policy scope include all projects
 * This is state when projects: { excluding: [] }
 * @param policyScope policyScope policy scope object on security policy
 * @returns {boolean}
 */
export const policyHasAllProjectsInGroup = (policyScope) => {
  if (isDefaultMode(policyScope)) return false;

  const { projects: { excluding = [] } = {} } = policyScope || {};
  return Boolean(excluding) && excluding?.filter(Boolean).length === 0;
};

/**
 * Check if policy scope has compliance frameworks
 * @param policyScope policyScope policy scope object on security policy
 * @returns {boolean}
 */
export const policyScopeHasComplianceFrameworks = (policyScope = {}) => {
  const { compliance_frameworks: complianceFrameworks = [] } = policyScope || {};
  return Boolean(complianceFrameworks) && complianceFrameworks?.filter(Boolean).length > 0;
};

/**
 * Extract ids from compliance frameworks
 * @param policyScope policyScope policy scope object on security policy
 * @returns {Array}
 */
export const policyScopeComplianceFrameworkIds = (policyScope = {}) => {
  return policyScope?.compliance_frameworks?.map(({ id }) => id).filter(Boolean) || [];
};
