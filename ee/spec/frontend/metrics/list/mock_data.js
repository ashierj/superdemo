export const mockMetrics = [
  {
    name: 'metric.a',
    description: 'a counter metric called A',
    type: 'COUNTER',
    last_ingested_at: 1705253554585113900,
    attributes: ['attribute_a', 'attribute_b'],
  },
  {
    name: 'metric.b',
    description: 'a gauge metric called B',
    type: 'GAUGE',
    last_ingested_at: 1704830670747000000,
    attributes: ['attribute_b', 'attribute_c'],
  },
  {
    name: 'metric.c',
    description: 'a histogram metric called C',
    type: 'HISTOGRAM',
    last_ingested_at: 1705255991365000000,
    attributes: ['attribute_d', 'attribute_c'],
  },
  {
    name: 'metric.d',
    description: 'a exp histogram metric called D',
    type: 'EXPONENTIAL HISTOGRAM',
    last_ingested_at: 1704830702229904600,
    attributes: ['attribute_b', 'attribute_a'],
  },
];
