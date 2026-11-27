module.exports = {
  testEnvironment: "jsdom",
  roots: ["<rootDir>/spec/javascript"],
  moduleDirectories: ["node_modules", "app/packs"],
  setupFilesAfterEnv: ["<rootDir>/spec/javascript/setup.js"],
  transform: {
    "^.+\\.js$": [
      "babel-jest",
      {
        babelrc: false,
        configFile: false,
        presets: [
          ["@babel/preset-env", { targets: { node: "current" } }]
        ]
      }
    ]
  }
};
