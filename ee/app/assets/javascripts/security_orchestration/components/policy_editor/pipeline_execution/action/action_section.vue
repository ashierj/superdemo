<script>
import { ACTIONS_LABEL } from '../../constants';
import CodeBlockFilePath from '../../scan_execution/action/code_block_file_path.vue';

export default {
  i18n: {
    ACTIONS_LABEL,
  },
  components: {
    CodeBlockFilePath,
  },
};
</script>

<template>
  <code-block-file-path />
</template>
