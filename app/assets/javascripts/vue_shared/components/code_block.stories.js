import CodeBlock from './code_block.vue';

export default {
  component: CodeBlock,
  title: 'vue_shared/components/code_block',
};

const Template = (args, { argTypes }) => ({
  components: { CodeBlock },
  props: Object.keys(argTypes),
  template: '<code-block v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  code: `git commit -a "Message"\ngit push`,
};
