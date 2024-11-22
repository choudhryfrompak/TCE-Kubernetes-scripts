import repoConfig from "@repo/eslint-config/react-app";
import tsParser from "@typescript-eslint/parser";

export default tseslint.config({
  files: ["**/*.{js,jsx,ts,tsx}"],
  extends: [repoConfig],
  languageOptions: {
    parser: tsParser,
    parserOptions: {
      project: true,
    },
  },
});
