import repoConfig from "../../packages/eslint-config/react-app.mjs";
import tseslint from "typescript-eslint";

export default tseslint.config({
  files: ["**/*.{js,jsx,ts,tsx}"],
  extends: [repoConfig],
});
