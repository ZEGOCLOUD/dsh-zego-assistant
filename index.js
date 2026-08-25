// dsh-zego-assistant — bundled ZEGO skill provider for DeepSeek Harness.
//
// Registers the five zego-assistant skills on ctx.skills, following the
// bundled-provider pattern of dsh-agora / @deepseek-ai/dsh-skill-badge: a
// Cordis plugin whose apply() registers one provider.
//
// assets/skills/ is vendored verbatim from ZEGOCLOUD/zego-claude-code-plugins
// (plugins/zego-assistant/skills). SKILL.md frontmatter stays the single
// source of truth: name/description/version are parsed at list() time, and
// get() returns the body with the frontmatter stripped.
//
// The doc-ai MCP server is wired separately in cordis.patch.yml via
// @deepseek-ai/dsh-mcp-client (serverName ZEGO), so its tools arrive as
// mcp__ZEGO__<rawName> — the same server-qualified shape Claude Code uses,
// which is what the SKILL.md bodies already reference.
import { readFile } from 'node:fs/promises'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { BUNDLED_SKILL_RANK } from '@deepseek-ai/dsh-skill'

const PROVIDER_NAME = 'zego'
const SKILLS_ROOT = fileURLToPath(new URL('./assets/skills/', import.meta.url))
const SKILL_NAMES = [
  'integrate-zego-product',
  'implement-zego-token-on-server',
  'integrate-zego-server-api',
  'resource-downloader',
  'search-zego-doc-fragments',
]

function parseFrontmatter(raw) {
  const match = /^---\r?\n([\s\S]*?)\r?\n---/.exec(raw)
  if (!match) return { frontmatter: {}, body: raw }
  const frontmatter = {}
  for (const line of match[1].split(/\r?\n/)) {
    const sep = line.indexOf(':')
    if (sep <= 0) continue
    const key = line.slice(0, sep).trim()
    const value = line.slice(sep + 1).trim()
    if (value) frontmatter[key] = value
  }
  const body = raw.slice(match[0].length).replace(/^\r?\n/, '')
  return { frontmatter, body }
}

async function loadCandidate(skillDirName) {
  const skillDir = join(SKILLS_ROOT, skillDirName)
  const bodyPath = join(skillDir, 'SKILL.md')
  const { frontmatter } = parseFrontmatter(await readFile(bodyPath, 'utf8'))
  const metadata = {}
  if (frontmatter.version) metadata.version = frontmatter.version
  return {
    name: frontmatter.name ?? skillDirName,
    description: frontmatter.description ?? '',
    invocation: {
      modelInvocable: true,
      userInvocable: true,
    },
    provider: PROVIDER_NAME,
    source: 'bundled',
    resourceBase: {
      kind: 'directory',
      path: skillDir,
    },
    rank: BUNDLED_SKILL_RANK,
    locator: bodyPath,
    metadata,
  }
}

const provider = {
  name: PROVIDER_NAME,
  list: () => Promise.all(SKILL_NAMES.map(loadCandidate)),
  async get(candidate) {
    const { body } = parseFrontmatter(await readFile(candidate.locator, 'utf8'))
    return { ...candidate, content: body }
  },
}

/** Cordis plugin name. */
export const name = 'zego-skills'
/** Service required by the bundled provider. */
export const inject = ['skills']
/** Register the bundled `zego` provider on `ctx.skills`. */
export function apply(ctx) {
  ctx.skills.registerProvider(() => provider)
}
