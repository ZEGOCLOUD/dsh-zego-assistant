// Smoke test: load the plugin with a stub ctx and exercise the real provider
// (list + get) against the bundled assets. Run: node test/smoke.mjs
import { access } from 'node:fs/promises'
import assert from 'node:assert/strict'

const mod = await import('../index.js')

assert.equal(mod.name, 'zego-skills', 'plugin name export')
assert.deepEqual(mod.inject, ['skills'], 'inject export')

let provider
const ctx = {
  skills: {
    registerProvider: (create) => {
      provider = create()
      return () => {}
    },
  },
}
mod.apply(ctx)
assert.equal(provider.name, 'zego', 'provider name')

const candidates = await provider.list({})
assert.equal(candidates.length, 5, 'five candidates')
console.log(`list() -> ${candidates.length} candidates`)

const expected = [
  'implement-zego-token-on-server',
  'integrate-zego-product',
  'integrate-zego-server-api',
  'resource-downloader',
  'search-zego-doc-fragments',
]
for (const c of candidates) {
  assert.match(c.name, /^[a-z0-9]+(?:-[a-z0-9]+)*$/, `kebab-case name: ${c.name}`)
  assert.ok(expected.includes(c.name), `known name: ${c.name}`)
  assert.ok(c.description.length > 50, `description present: ${c.name}`)
  assert.equal(c.source, 'bundled', `source: ${c.name}`)
  assert.equal(c.provider, 'zego', `provider: ${c.name}`)
  assert.equal(c.rank, 600, `rank: ${c.name}`)
  assert.deepEqual(
    c.invocation,
    { modelInvocable: true, userInvocable: true },
    `invocation: ${c.name}`,
  )
  assert.equal(c.resourceBase.kind, 'directory', `resourceBase kind: ${c.name}`)
  await access(c.resourceBase.path)
  await access(c.locator)
  assert.ok(c.metadata.version, `metadata.version: ${c.name}`)
}

for (const c of candidates) {
  const def = await provider.get(c, {})
  assert.equal(def.name, c.name, `get name matches candidate: ${c.name}`)
  assert.ok(def.content.length > 200, `body present: ${c.name}`)
  assert.ok(
    !def.content.startsWith('---'),
    `frontmatter stripped: ${c.name}`,
  )
  assert.ok(!('body' in def), 'no stray body field')
  console.log(
    `get()  -> ${def.name.padEnd(34)} v${def.metadata.version}  body=${def.content.length} chars`,
  )
}

console.log('\nAll smoke assertions passed.')
