import { mapParallel as CEMapParallel } from '~/diffs/components/diff_row_utils';
import { fileLineCodequality, fileLineSast } from './inline_findings_utils';

export const mapParallel = (content, codequalityData, sastData) => (line) => {
  let { left, right } = line;

  if (left) {
    left = {
      ...left,
      codequality: fileLineCodequality(content.diffFile.file_path, left.new_line, codequalityData),
      sast: fileLineSast(content.diffFile.file_path, left.new_line, sastData),
    };
  }
  if (right) {
    right = {
      ...right,
      codequality: fileLineCodequality(content.diffFile.file_path, right.new_line, codequalityData),
      sast: fileLineSast(content.diffFile.file_path, right.new_line, sastData),
    };
  }

  return {
    ...CEMapParallel(content)({
      ...line,
      left,
      right,
    }),
  };
};
