import { safeDump, safeLoad } from 'js-yaml';
import { addIdsToPolicy, removeIdsFromPolicy } from '../utils';

/*
  Construct a policy object expected by the policy editor from a yaml manifest.
*/
export const fromYaml = ({ manifest }) => {
  try {
    const policy = addIdsToPolicy(safeLoad(manifest, { json: true }));

    return policy;
  } catch {
    /**
     * Catch parsing error of safeLoad
     */
    return { error: true, key: 'yaml-parsing' };
  }
};

/**
 * Converts a security policy from yaml to an object
 * @param {String} manifest a security policy in yaml form
 * @returns {Object} security policy object and any errors
 */
export const createPolicyObject = (manifest) => {
  const policy = fromYaml({ manifest });

  return { policy, hasParsingError: Boolean(policy.error) };
};

/*
 Return yaml representation of a policy.
*/
export const policyToYaml = (policy) => {
  return safeDump(removeIdsFromPolicy(policy));
};

export const toYaml = (yaml) => {
  return safeDump(yaml);
};
