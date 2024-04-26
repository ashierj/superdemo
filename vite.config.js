import { readFileSync } from 'node:fs';
import { stat, mkdir, copyFile } from 'node:fs/promises';
import path from 'node:path';

import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue2';
import graphql from '@rollup/plugin-graphql';
import globby from 'globby';
import { viteCommonjs } from '@originjs/vite-plugin-commonjs';
import webpackConfig from './config/webpack.config';
import { generateEntries } from './config/webpack.helpers';
import {
  IS_EE,
  IS_JH,
  SOURCEGRAPH_PUBLIC_PATH,
  GITLAB_WEB_IDE_PUBLIC_PATH,
  copyFilesPatterns,
} from './config/webpack.constants';
/* eslint-disable import/extensions */
import { viteCSSCompilerPlugin } from './scripts/frontend/lib/compile_css.mjs';
import { viteTailwindCompilerPlugin } from './scripts/frontend/tailwindcss.mjs';
import { AutoStopPlugin } from './config/helpers/vite_plugin_auto_stop.mjs';
import { FixedRubyPlugin } from './config/helpers/vite_plugin_ruby_fixed.mjs';
/* eslint-enable import/extensions */

let viteGDKConfig;
try {
  viteGDKConfig = JSON.parse(
    readFileSync(path.resolve(__dirname, 'config/vite.gdk.json'), 'utf-8'),
  );
} catch {
  viteGDKConfig = {};
}

const aliasArr = Object.entries(webpackConfig.resolve.alias).map(([find, replacement]) => ({
  find: find.includes('$') ? new RegExp(find) : find,
  replacement,
}));

const assetsPath = path.resolve(__dirname, 'app/assets');
const javascriptsPath = path.resolve(assetsPath, 'javascripts');

const emptyComponent = path.resolve(javascriptsPath, 'vue_shared/components/empty_component.js');

const comment = '/* this is a virtual module used by Vite, it exists only in dev mode */\n';

const virtualEntrypoints = Object.entries(generateEntries()).reduce((acc, [entryName, imports]) => {
  const modulePath = imports[imports.length - 1];
  const importPath = modulePath.startsWith('./') ? `~/${modulePath.substring(2)}` : modulePath;
  acc[`${entryName}.js`] = `${comment}/* ${modulePath} */ import '${importPath}';\n`;
  return acc;
}, {});

const EE_ALIAS_FALLBACK = [
  {
    find: /^ee_component\/(.*)\.vue/,
    replacement: emptyComponent,
  },
];

const JH_ALIAS_FALLBACK = [
  {
    find: /^jh_component\/(.*)\.vue/,
    replacement: emptyComponent,
  },
];

/**
 * This is a simple-reimplementation of the copy-webpack-plugin
 *
 * it also uses the `globby` package under the hood, and _only_ allows for copying
 * 1. absolute paths
 * 2. files and directories.
 */
function viteCopyPlugin({ patterns }) {
  return {
    name: 'viteCopyPlugin',
    async configureServer() {
      console.warn('Start copying files...');
      let count = 0;

      const allTheFiles = patterns.map(async (patternEntry) => {
        const { from, to, globOptions = {} } = patternEntry;

        // By only supporting absolute paths we simplify
        // the implementation a lot
        if (!path.isAbsolute(from)) {
          throw new Error(`'from' path is not absolute: ${path}`);
        }
        if (!path.isAbsolute(to)) {
          throw new Error(`'to' path is not absolute: ${path}`);
        }

        let pattern = '';
        let sourceRoot = '';
        const fromStat = await stat(from);
        if (fromStat.isDirectory()) {
          sourceRoot = from;
          pattern = path.join(from, '**/*');
        } else if (fromStat.isFile()) {
          sourceRoot = path.dirname(from);
          pattern = from;
        } else {
          // No need to support globs, because we do not
          // use them yet...
          throw new Error('Our implementation does not support globs.');
        }

        globOptions.dot = globOptions.dot ?? true;

        const paths = await globby(pattern, globOptions);

        return paths.map((srcPath) => {
          const targetPath = path.join(to, path.relative(sourceRoot, srcPath));
          return { srcPath, targetPath };
        });
      });

      const srcTargetMap = (await Promise.all(allTheFiles)).flat();

      await Promise.all(
        srcTargetMap.map(async ({ srcPath, targetPath }) => {
          try {
            await mkdir(path.dirname(targetPath), { recursive: true });
            await copyFile(srcPath, targetPath);
            count += 1;
          } catch (e) {
            console.warn(`Could not copy ${srcPath} => ${targetPath}`);
          }
        }),
      );

      console.warn(`Done copying ${count} files...`);
    },
  };
}

const entrypointsDir = '/javascripts/entrypoints/';
const pageEntrypointsPlugin = {
  name: 'page-entrypoints',
  load(id) {
    if (!id.startsWith('pages.')) {
      return undefined;
    }
    return virtualEntrypoints[id] ?? `/* doesn't exist */`;
  },
  resolveId(source) {
    const fixedSource = source.replace(entrypointsDir, '');
    if (fixedSource.startsWith('pages.')) return { id: fixedSource };
    return undefined;
  },
};

export default defineConfig({
  cacheDir: path.resolve(__dirname, 'tmp/cache/vite'),
  resolve: {
    alias: [
      ...aliasArr,
      ...(IS_EE ? [] : EE_ALIAS_FALLBACK),
      ...(IS_JH ? [] : JH_ALIAS_FALLBACK),
      {
        find: '~/',
        replacement: javascriptsPath,
      },
      {
        find: '~katex',
        replacement: 'katex',
      },
    ],
  },
  plugins: [
    pageEntrypointsPlugin,
    viteCSSCompilerPlugin({ shouldWatch: viteGDKConfig.hmr !== null }),
    viteTailwindCompilerPlugin({ shouldWatch: viteGDKConfig.hmr !== null }),
    viteCopyPlugin({
      patterns: copyFilesPatterns,
    }),
    viteGDKConfig.enabled ? AutoStopPlugin() : null,
    FixedRubyPlugin(),
    vue({
      template: {
        compilerOptions: {
          whitespace: 'preserve',
        },
      },
    }),
    graphql(),
    viteCommonjs({
      include: [path.resolve(javascriptsPath, 'locale/ensure_single_line.cjs')],
    }),
  ],
  define: {
    // window can be undefined in a Web Worker
    IS_EE: IS_EE
      ? JSON.stringify('typeof window !== "undefined" && window.gon && window.gon.ee')
      : JSON.stringify(false),
    IS_JH: IS_JH
      ? JSON.stringify('typeof window !== "undefined" && window.gon && window.gon.jh')
      : JSON.stringify(false),
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    'process.env.SOURCEGRAPH_PUBLIC_PATH': JSON.stringify(SOURCEGRAPH_PUBLIC_PATH),
    'process.env.GITLAB_WEB_IDE_PUBLIC_PATH': JSON.stringify(GITLAB_WEB_IDE_PUBLIC_PATH),
  },
  server: {
    hmr: viteGDKConfig.hmr,
    https: false,
    watch:
      viteGDKConfig.hmr === null
        ? null
        : {
            ignored: [
              '**/*.stories.js',
              '**/css_in_js.js',
              function ignoreRootFolder(x) {
                /*
             `vite` watches the root folder of gitlab and all of its sub folders
             This is not what we want, because we have temp files, and all kind
             of other stuff. As vite starts its watchers recursively, we just
             ignore if the path matches exactly the root folder

             Additional folders like `ee/app/assets` are defined in
             */
                return x === __dirname;
              },
            ],
          },
  },
  worker: {
    format: 'es',
  },
  build: {
    rollupOptions: {
      input: Object.keys(virtualEntrypoints).reduce((acc, value) => {
        acc[value] = value;
        return acc;
      }, {}),
    },
  },
});
