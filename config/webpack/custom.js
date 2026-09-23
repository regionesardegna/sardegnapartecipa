/* eslint-disable */
process.env.NODE_ENV ??= "development"

const { config } = require("shakapacker");
const { InjectManifest } = require("workbox-webpack-plugin");
const TerserPlugin = require('terser-webpack-plugin')

module.exports = {
  module: {
    rules: [
      {
        test: require.resolve("jquery"),
        loader: "expose-loader",
        options: { exposes: ["$", "jQuery"] }
      },
      {
        test: /\.(js|jsx)$/,
        // Escludiamo categoricamente node_modules da Babel in modo che formBuilder non venga toccato
        exclude: /node_modules/,
        loader: "babel-loader",
        options: {
          cacheDirectory: true
        }
      },
      {
        test: /\.(graphql|gql)$/,
        loader: "graphql-tag/loader"
      },
      {
        test: require.resolve("react"),
        loader: "expose-loader",
        options: { exposes: ["React"] }
      },
      {
        test: require.resolve("@rails/ujs"),
        loader: "expose-loader",
        options: { exposes: ["Rails"] }
      },
      {
        test: [/\.md$/, /\.odt$/],
        exclude: [/\.(js|mjs|jsx|ts|tsx)$/],
        type: 'asset/resource',
        generator: { filename: 'media/documents/[hash][ext][query]' }
      },
      {
        test: [
          /\.bmp$/, /\.gif$/, /\.jpe?g$/, /\.png$/, /\.tiff$/, /\.ico$/,
          /\.avif$/, /\.webp$/, /\.eot$/, /\.otf$/, /\.ttf$/, /\.woff$/, /\.woff2$/, /\.svg$/
        ],
        exclude: [/\.(js|mjs|jsx|ts|tsx)$/],
        type: 'asset/resource',
        generator: { filename: 'media/images/[name]-[hash][ext][query]' }
      }
    ]
  },
  resolve: {
    extensions: [".js", ".jsx", ".gql", ".graphql"],
    fallback: { crypto: false }
  },
  optimization: {
    minimizer: [
      new TerserPlugin({
        parallel: Number.parseInt(process.env.SHAKAPACKER_PARALLEL, 10) || true,
        terserOptions: {
          parse: { ecma: 8 },
          compress: { ecma: 5, warnings: false, comparisons: false },
          mangle: { safari10: true },
          output: { ecma: 5, comments: false, ascii_only: true }
        }
      })
    ].filter(Boolean)
  },
  entry: config.entrypoints,
  plugins: [
    new InjectManifest({
      swSrc: "src/decidim/sw/sw.js",
      swDest: "../sw.js"
    })
  ]
}