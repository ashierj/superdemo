<script>
export default {
  name: 'AiImpactTable',
  props: {
    data: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <small>
    {{ JSON.stringify(data) }}
  </small>
</template>
