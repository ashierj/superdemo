<script>
import { debounce } from 'lodash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Api from 'ee/api';
import { parseCustomFileConfiguration } from 'ee/security_orchestration/components/policy_editor/utils';
import CodeBlockFileFilePath from '../../scan_execution/action/code_block_file_path.vue';
import { INJECT, OVERRIDE } from '../../scan_execution/constants';

export default {
  components: {
    CodeBlockFileFilePath,
  },
  props: {
    action: {
      type: Object,
      required: true,
    },
    overrideType: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    const { project: selectedProject } = parseCustomFileConfiguration(this.action.include);

    return {
      doesFileExist: true,
      selectedProject,
    };
  },
  computed: {
    ciConfigurationPath() {
      return this.action.include || {};
    },
    filePath() {
      return this.ciConfigurationPath.file;
    },
    overrideString() {
      return this.overrideType ? OVERRIDE : INJECT;
    },
    selectedRef() {
      return this.ciConfigurationPath.ref;
    },
  },
  watch: {
    filePath() {
      this.resetValidation();
      this.handleFileValidation();
    },
    selectedProject() {
      this.resetValidation();
      this.handleFileValidation();
    },
    selectedRef() {
      this.resetValidation();
      this.handleFileValidation();
    },
  },
  created() {
    this.handleFileValidation = debounce(this.validateFilePath, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  mounted() {
    this.validateFilePath();
  },
  methods: {
    resetValidation() {
      if (!this.doesFileExist) {
        this.doesFileExist = true;
      }
    },
    setOverride(overrideType) {
      this.$emit('changed', 'override_project_ci', overrideType === OVERRIDE);
    },
    setSelectedRef(ref) {
      this.setCiConfigurationPath({ ...this.ciConfigurationPath, ref });
    },
    setSelectedProject(project) {
      this.selectedProject = null;
      this.$nextTick(() => {
        this.selectedProject = project;

        const config = { ...this.ciConfigurationPath };

        if ('ref' in config) delete config.ref;

        if (project) {
          config.project = project?.fullPath;
          config.id = getIdFromGraphQLId(project?.id);
        } else {
          delete config.project;
          delete config.id;
        }

        this.setCiConfigurationPath({ ...config });
      });
    },
    updatedFilePath(path) {
      this.setCiConfigurationPath({ ...this.ciConfigurationPath, file: path });
    },
    async validateFilePath() {
      const selectedProjectId = getIdFromGraphQLId(this.selectedProject?.id);
      const ref = this.selectedRef || this.selectedProject?.repository?.rootRef;

      // For when the id is removed or when selectedProject is set to null temporarily above
      if (!selectedProjectId) {
        this.doesFileExist = false;
        return;
      }

      // For existing policies with existing project selected, rootRef will not be available
      if (!ref) {
        this.doesFileExist = true;
        return;
      }

      try {
        await Api.getFile(selectedProjectId, this.filePath, { ref });
        this.doesFileExist = true;
      } catch {
        this.doesFileExist = false;
      }
    },
    setCiConfigurationPath(pathConfig) {
      this.$emit('changed', 'content', { include: pathConfig });
    },
  },
};
</script>

<template>
  <code-block-file-file-path
    :file-path="filePath"
    :override-type="overrideString"
    :selected-ref="selectedRef"
    :selected-project="selectedProject"
    :does-file-exist="doesFileExist"
    @select-override="setOverride"
    @select-ref="setSelectedRef"
    @select-project="setSelectedProject"
    @update-file-path="updatedFilePath"
  />
</template>
