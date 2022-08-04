module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/strict',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
  ],
  rules: {
    'brace-style': ['error', '1tbs', { 'allowSingleLine': true }],
    'semi': ['error'],
    'array-bracket-spacing': ['error'],
    'arrow-spacing': ['error'],
    'comma-spacing': ['error'],
    'comma-style': ['error'],
    'eol-last': ['error'],
    'indent': ['error', 2],
    'comma-dangle': ['error', 'always-multiline'],
    'no-unused-vars': ['error', { 'argsIgnorePattern': '^_' }],
    '@typescript-eslint/no-unused-vars': ['error', { 'argsIgnorePattern': '^_' }],
    '@typescript-eslint/no-non-null-assertion': 'off'
  },
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  root: true,
  parserOptions: {
    tsconfigRootDir: __dirname,
    project: ['src/tsconfig.json'],
  },
};
