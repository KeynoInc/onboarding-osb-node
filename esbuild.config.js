import { build } from 'esbuild'

build({
  entryPoints: ['src/app.ts'],
  bundle: true,
  outdir: 'dist',
  platform: 'node',
  format: 'cjs',
  target: ['esnext'],
  sourcemap: false,
  tsconfig: 'tsconfig.json',
  external: [],
  loader: {
    '.ts': 'ts',
  },
  logLevel: 'info',
  plugins: [
    {
      name: 'date-fns-external',
      setup(build) {
        build.onResolve({ filter: /^date-fns$/ }, () => ({ external: true }))
      },
    },
  ].filter(Boolean),
})
  .then(() => {
    console.log('Build completed successfully!')
  })
  .catch(err => {
    console.error('Build failed:', err)
    process.exit(1)
  })
