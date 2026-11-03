#!/usr/bin/env node
// 极简 CDP 客户端：在一个已开调试端口的 Chrome 页面上执行 JS。
//
// 为什么自己写：本机没有 websocket-client / puppeteer，但 Node 22 自带全局
// WebSocket，够用了，零依赖。
//
// 用法：
//   node tool/cdp.mjs "location.href"                 # 执行表达式并打印结果
//   node tool/cdp.mjs --match ugdocker "location.href" # 只挑 URL 含该串的标签页
//   node tool/cdp.mjs --nav "https://..."              # 导航当前页
//   node tool/cdp.mjs --file /tmp/x.js                 # 执行脚本文件（可 await）
//
// 环境变量：CDP_PORT（默认 9333）

const PORT = process.env.CDP_PORT || '9333';
const base = `http://127.0.0.1:${PORT}`;

function args() {
  const a = process.argv.slice(2);
  const out = { match: null, nav: null, file: null, expr: null };
  while (a.length) {
    const t = a.shift();
    if (t === '--match') out.match = a.shift();
    else if (t === '--nav') out.nav = a.shift();
    else if (t === '--file') out.file = a.shift();
    else out.expr = t;
  }
  return out;
}

async function pickTarget(match) {
  const res = await fetch(`${base}/json/list`);
  const list = await res.json();
  const pages = list.filter((t) => t.type === 'page');
  if (!pages.length) throw new Error('没有可用的页面目标');
  if (match) {
    const hit = pages.find((p) => (p.url || '').includes(match));
    if (hit) return hit;
  }
  // 优先挑 http(s) 页面（跳过 about:blank / 内部页）
  return pages.find((p) => /^https?:/.test(p.url || '')) || pages[0];
}

async function main() {
  const { match, nav, file, expr } = args();
  const target = await pickTarget(match);
  console.error(`# target: ${target.title} | ${target.url}`);

  const ws = new WebSocket(target.webSocketDebuggerUrl);
  let id = 0;
  const pending = new Map();
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const msgId = ++id;
      pending.set(msgId, { resolve, reject });
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });

  await new Promise((resolve, reject) => {
    ws.onopen = resolve;
    ws.onerror = (e) => reject(new Error(`WS 连接失败: ${e.message || e}`));
  });

  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
    }
  };

  try {
    if (nav) {
      const r = await send('Page.navigate', { url: nav });
      console.log(JSON.stringify(r));
      return;
    }

    const source = file
      ? (await import('node:fs')).readFileSync(file, 'utf8')
      : expr;
    if (!source) throw new Error('没有表达式。用法见文件头。');

    const r = await send('Runtime.evaluate', {
      expression: source,
      awaitPromise: true,
      returnByValue: true,
      userGesture: true,
      allowUnsafeEvalBlockedByCSP: true,
    });
    if (r.exceptionDetails) {
      console.error('JS 异常：', JSON.stringify(r.exceptionDetails, null, 2).slice(0, 1200));
      process.exitCode = 1;
      return;
    }
    const v = r.result?.value;
    console.log(typeof v === 'string' ? v : JSON.stringify(v, null, 2));
  } finally {
    ws.close();
  }
}

main().catch((e) => {
  console.error('失败：', e.message);
  process.exit(1);
});
