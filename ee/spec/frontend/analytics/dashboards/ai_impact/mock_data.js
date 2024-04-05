export const mockDoraTimePeriods = [
  {
    key: '6-months-ago',
    label: 'Oct',
    start: new Date('2023-10-01T00:00:00.000Z'),
    end: new Date('2023-10-31T23:59:59.000Z'),
    thClass: 'gl-w-10p',
    deployment_frequency: {
      identifier: 'deployment_frequency',
      value: 10,
    },
    change_failure_rate: {
      identifier: 'change_failure_rate',
      value: '8.9',
    },
  },
  {
    key: '5-months-ago',
    label: 'Nov',
    start: new Date('2023-11-01T00:00:00.000Z'),
    end: new Date('2023-11-30T23:59:59.000Z'),
    thClass: 'gl-w-10p',
    deployment_frequency: {
      identifier: 'deployment_frequency',
      value: 15,
    },
    change_failure_rate: {
      identifier: 'change_failure_rate',
      value: '5.6',
    },
  },
  {
    key: '4-months-ago',
    label: 'Dec',
    start: new Date('2023-12-01T00:00:00.000Z'),
    end: new Date('2024-12-31T23:59:59.000Z'),
    thClass: 'gl-w-10p',
    deployment_frequency: {
      identifier: 'deployment_frequency',
      value: null,
    },
    change_failure_rate: {
      identifier: 'change_failure_rate',
      value: '0.0',
    },
  },
  {
    key: '3-months-ago',
    label: 'Jan',
    start: new Date('2024-01-01T00:00:00.000Z'),
    end: new Date('2024-01-31T23:59:59.000Z'),
    thClass: 'gl-w-10p',
    deployment_frequency: {
      identifier: 'deployment_frequency',
      value: 30,
    },
    change_failure_rate: {
      identifier: 'change_failure_rate',
      value: null,
    },
  },
  {
    key: '2-months-ago',
    label: 'Feb',
    start: new Date('2024-02-01T00:00:00.000Z'),
    end: new Date('2024-02-29T23:59:59.000Z'),
    thClass: 'gl-w-10p',
    deployment_frequency: {
      identifier: 'deployment_frequency',
      value: '-',
    },
    change_failure_rate: {
      identifier: 'change_failure_rate',
      value: '7.5',
    },
  },
  {
    key: '1-months-ago',
    label: 'Mar',
    start: new Date('2024-03-01T00:00:00.000Z'),
    end: new Date('2024-03-31T23:59:59.000Z'),
    thClass: 'gl-w-10p',
    deployment_frequency: {
      identifier: 'deployment_frequency',
      value: 30,
    },
    change_failure_rate: {
      identifier: 'change_failure_rate',
      value: '4.0',
    },
  },
];
