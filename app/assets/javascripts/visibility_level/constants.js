export const VISIBILITY_LEVEL_PRIVATE_STRING = 'private';
export const VISIBILITY_LEVEL_INTERNAL_STRING = 'internal';
export const VISIBILITY_LEVEL_PUBLIC_STRING = 'public';

export const VISIBILITY_LEVEL_PRIVATE_INTEGER = 0;
export const VISIBILITY_LEVEL_INTERNAL_INTEGER = 10;
export const VISIBILITY_LEVEL_PUBLIC_INTEGER = 20;

// Matches `lib/gitlab/visibility_level.rb`
export const VISIBILITY_LEVELS_STRING_TO_INTEGER = {
  [VISIBILITY_LEVEL_PRIVATE_STRING]: VISIBILITY_LEVEL_PRIVATE_INTEGER,
  [VISIBILITY_LEVEL_INTERNAL_STRING]: VISIBILITY_LEVEL_INTERNAL_INTEGER,
  [VISIBILITY_LEVEL_PUBLIC_STRING]: VISIBILITY_LEVEL_PUBLIC_INTEGER,
};

export const VISIBILITY_LEVELS_INTEGER_TO_STRING = {
  [VISIBILITY_LEVEL_PRIVATE_INTEGER]: VISIBILITY_LEVEL_PRIVATE_STRING,
  [VISIBILITY_LEVEL_INTERNAL_INTEGER]: VISIBILITY_LEVEL_INTERNAL_STRING,
  [VISIBILITY_LEVEL_PUBLIC_INTEGER]: VISIBILITY_LEVEL_PUBLIC_STRING,
};
