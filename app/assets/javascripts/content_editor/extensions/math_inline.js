import { Mark, markInputRule } from '@tiptap/core';
import { __ } from '~/locale';
import { PARSE_HTML_PRIORITY_HIGH } from '../constants';

export default Mark.create({
  name: 'mathInline',

  parseHTML() {
    return [
      // Matches HTML generated by Banzai::Filter::MarkdownFilter
      {
        tag: 'code[data-math-style=inline]',
        priority: PARSE_HTML_PRIORITY_HIGH,
      },
      // Matches HTML after being transformed by app/assets/javascripts/behaviors/markdown/render_math.js
      {
        tag: 'span.katex',
        contentElement: 'annotation[encoding="application/x-tex"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      'code',
      {
        title: __('Inline math'),
        'data-toggle': 'tooltip',
        class: 'gl-inset-border-1-gray-400',
        ...HTMLAttributes,
      },
      0,
    ];
  },

  addInputRules() {
    const inputRegex = /(?:^|\s)\$`([^`]+)`\$$/gm;

    return [markInputRule({ find: inputRegex, type: this.type })];
  },
});
