export const generateVulnerabilities = () => [
  {
    id: 'id_0',
    identifiers: [
      {
        externalType: 'cve',
        name: 'CVE-2018-1234',
      },
      {
        externalType: 'gemnasium',
        name: 'Gemnasium-2018-1234',
      },
    ],
    title: 'Vulnerability 0',
    severity: 'critical',
    state: 'dismissed',
    reportType: 'SAST',
    location: {
      image:
        'registry.gitlab.com/groulot/container-scanning-test/master:5f21de6956aee99ddb68ae49498662d9872f50ff',
    },
    project: {
      nameWithNamespace: 'Administrator / Security reports',
    },
  },
  {
    id: 'id_1',
    identifiers: [
      {
        externalType: 'gemnasium',
        name: 'Gemnasium-2018-1234',
      },
    ],
    title: 'Vulnerability 1',
    severity: 'high',
    state: 'opened',
    reportType: 'DEPENDENCY_SCANNING',
    location: {
      file: 'src/main/java/com/gitlab/security_products/tests/App.java',
    },
    project: {
      nameWithNamespace: 'Administrator / Vulnerability reports',
    },
  },
  {
    id: 'id_2',
    title: 'Vulnerability 2',
    severity: 'high',
    state: 'opened',
    reportType: 'CUSTOM_SCANNER_WITHOUT_TRANSLATION',
    location: {
      file: 'yarn.lock',
    },
    project: {
      nameWithNamespace: 'Mixed Vulnerabilities / Dependency List Test 01',
    },
  },
  {
    id: 'id_3',
    title: 'Vulnerability 3',
    severity: 'high',
    state: 'opened',
    location: {
      file: 'yarn.lock',
    },
    project: {
      nameWithNamespace: 'Mixed Vulnerabilities / Dependency List Test 01',
    },
  },
];

export const vulnerabilities = generateVulnerabilities();
