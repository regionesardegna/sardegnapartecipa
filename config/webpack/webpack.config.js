/* eslint-disable */
const crypto = require("crypto");
if (!globalThis.crypto) {
  globalThis.crypto = crypto.webcrypto;
}

process.env.NODE_ENV ??= "development"

const { webpackConfig, merge } = require("@decidim/webpacker")
const customConfig = require("./custom")

// Intercettiamo l'array delle regole di webpack per blindare babel-loader
if (webpackConfig.module && webpackConfig.module.rules) {
  webpackConfig.module.rules.forEach(rule => {
    // Controlla se la regola gestisce i file js/jsx tramite babel-loader
    const isBabel = rule.loader?.includes('babel-loader') ||
        (Array.isArray(rule.use) && rule.use.some(u => (typeof u === 'string' && u.includes('babel-loader')) || u.loader?.includes('babel-loader')));

    if (isBabel) {
      // Forza l'esclusione di node_modules per evitare che formBuilder venga processato
      rule.exclude = /node_modules/;
    }
  });
}

webpackConfig.optimization = {}
const combinedConfig = merge(webpackConfig, customConfig)

module.exports = combinedConfig
