<script>
export default {
  name: 'RunnerUsageTable',
};
</script>

<template>
  <table class="table gl-table runners-usage-table">
    <thead role="rowgroup">
      <tr role="row">
        <th>
          <slot name="name"></slot>
        </th>
        <th class="gl-text-right">
          {{ s__('Runners|Usage (min)') }}
        </th>
      </tr>
    </thead>
    <tbody role="rowgroup">
      <slot></slot>
    </tbody>
  </table>
</template>
