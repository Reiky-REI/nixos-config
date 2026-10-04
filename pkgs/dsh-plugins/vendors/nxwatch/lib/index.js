// nxwatch 宿主半:守夜人驾驶舱的数据与资源路由。
// 作为 dsh web profile 的宿主行加载,向浏览器暴露:
//   GET /plugins/nxwatch/meta            — git/主机/沙箱默认档 JSON
//   GET /plugins/nxwatch/assets/hero.png — 守护甜心 hero 图
//   GET /plugins/nxwatch/assets/nix.png  — Nix 徽章
//   GET /plugins/nxwatch/ambient.mp4     — 动态壁纸(魔女之旅,支持 Range)
import { spawnSync } from 'node:child_process'
import { createReadStream, existsSync, statSync } from 'node:fs'
import { hostname, release } from 'node:os'

export const name = 'nxwatch'
export const inject = ['webServer']

const HERO = '/home/Reiky-REI/Pictures/Wallpapers/static/守护甜心.png'
const NIX_BADGE = '/home/Reiky-REI/Pictures/Wallpapers/static/nix.png'
const AMBIENT = '/home/Reiky-REI/Pictures/Wallpapers/videos/Wandering+Witch-The+Journey+of+Elaina.mp4'

function gitMeta() {
  try {
    const status = spawnSync('git', ['-C', '/etc/nixos', 'status', '--porcelain'], { encoding: 'utf8', timeout: 5000 })
    if (status.status !== 0) return { ok: false, error: (status.stderr || '').trim() }
    const dirty = status.stdout.split('\n').filter(Boolean)
    const head = spawnSync('git', ['-C', '/etc/nixos', 'log', '-1', '--pretty=%h %s'], { encoding: 'utf8', timeout: 5000 })
    const branch = spawnSync('git', ['-C', '/etc/nixos', 'branch', '--show-current'], { encoding: 'utf8', timeout: 5000 })
    return {
      ok: true,
      branch: branch.stdout.trim(),
      dirty: dirty.length,
      dirtyFiles: dirty.slice(0, 5),
      lastCommit: head.stdout.trim(),
    }
  } catch (error) {
    return { ok: false, error: String(error) }
  }
}

function sendJson(res, payload) {
  const body = JSON.stringify(payload)
  res.writeHead(200, { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' })
  res.end(body)
}

// 极简 Range 支持:视频拖动进度需要 206 分段响应。
function streamFile(req, res, filePath, contentType) {
  if (!existsSync(filePath)) {
    res.writeHead(404, { 'content-type': 'text/plain' })
    res.end('not found')
    return
  }
  const size = statSync(filePath).size
  const range = req.headers.range
  if (range !== undefined) {
    const match = /^bytes=(\d*)-(\d*)$/.exec(range)
    if (match !== null) {
      let start = match[1] === '' ? 0 : Number(match[1])
      let end = match[2] === '' ? size - 1 : Math.min(Number(match[2]), size - 1)
      if (start > end || start >= size) {
        res.writeHead(416, { 'content-range': `bytes */${size}` })
        res.end()
        return
      }
      res.writeHead(206, {
        'content-type': contentType,
        'content-length': String(end - start + 1),
        'content-range': `bytes ${start}-${end}/${size}`,
        'accept-ranges': 'bytes',
        'cache-control': 'private, max-age=3600',
      })
      createReadStream(filePath, { start, end }).pipe(res)
      return
    }
  }
  res.writeHead(200, {
    'content-type': contentType,
    'content-length': String(size),
    'accept-ranges': 'bytes',
    'cache-control': 'private, max-age=3600',
  })
  createReadStream(filePath).pipe(res)
}

export function apply(ctx) {
  const sandboxPolicy = ctx.get('sandboxPolicy')
  ctx.effect(() => ctx.webServer.register({
    kind: 'exact',
    path: '/plugins/nxwatch/meta',
    handler: (_req, res) => {
      sendJson(res, {
        ok: true,
        hostname: hostname(),
        kernel: release(),
        git: gitMeta(),
        defaultSandboxMode: sandboxPolicy?.defaultMode ?? 'unknown',
        assets: {
          hero: '/plugins/nxwatch/assets/hero.png',
          badge: '/plugins/nxwatch/assets/nix.png',
          ambient: '/plugins/nxwatch/ambient.mp4',
        },
      })
    },
  }), 'nxwatch: meta route')

  ctx.effect(() => ctx.webServer.register({
    kind: 'exact',
    path: '/plugins/nxwatch/assets/hero.png',
    handler: (req, res) => streamFile(req, res, HERO, 'image/png'),
  }), 'nxwatch: hero asset')

  ctx.effect(() => ctx.webServer.register({
    kind: 'exact',
    path: '/plugins/nxwatch/assets/nix.png',
    handler: (req, res) => streamFile(req, res, NIX_BADGE, 'image/png'),
  }), 'nxwatch: badge asset')

  ctx.effect(() => ctx.webServer.register({
    kind: 'exact',
    path: '/plugins/nxwatch/ambient.mp4',
    handler: (req, res) => streamFile(req, res, AMBIENT, 'video/mp4'),
  }), 'nxwatch: ambient video')
}
