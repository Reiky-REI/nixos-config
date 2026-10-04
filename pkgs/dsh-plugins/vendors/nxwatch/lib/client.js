window.__ModuleLoader__.load({
	id: "nxwatch",
	factory: (require) => {
		var module = { exports: {} };
		var exports = module.exports;
		Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });
		let react_jsx_runtime = require("react/jsx-runtime");
		let react = require("react");
		//#region nxwatch 守夜人值班室 v4 css
		const css = [
			// ── 整页氛围:极光(纯 CSS body::after,React 无法清除,必然显示且动) ──
			"body.nxwatch-active.nxwatch-aurora::after{content:'';pointer-events:none;position:fixed;inset:0;z-index:2147483000;opacity:calc(var(--nxw-aurora,0.7)*1.15);background-image:radial-gradient(66vw 66vw at 50% 50%,rgba(139,124,246,0.30),transparent 66%),radial-gradient(58vw 58vw at 50% 50%,rgba(76,139,217,0.26),transparent 66%),radial-gradient(48vw 48vw at 50% 50%,rgba(217,164,65,0.14),transparent 66%);background-size:160% 160%;background-repeat:no-repeat;background-position:94% -10%,-10% 114%,74% 60%;animation:nxwAuroraMove 24s ease-in-out infinite alternate;transition:opacity .4s ease}",
			"@keyframes nxwAuroraMove{from{background-position:96% -4%,-14% 120%,80% 56%}to{background-position:76% -22%,-2% 102%,64% 72%}}",
			"body.nxwatch-active.nxwatch-aurora:not([data-ds-dark-theme])::after{opacity:calc(var(--nxw-aurora,0.7)*0.45);background-image:radial-gradient(66vw 66vw at 50% 50%,rgba(139,124,246,0.13),transparent 70%),radial-gradient(58vw 58vw at 50% 50%,rgba(76,139,217,0.10),transparent 70%),radial-gradient(48vw 48vw at 50% 50%,rgba(217,164,65,0.06),transparent 70%)}",
			// ── 整页底色:夜色(开关 body.nxwatch-night) ──
			"body.nxwatch-active.nxwatch-night[data-ds-dark-theme]{--dsw-alias-bg-base:#14121f!important;--dsw-alias-bg-layer-1:#1b1830!important;--dsw-alias-bg-layer-2:#242040!important;--dsw-specific-sidebar-fill:#171427!important;--dsw-alias-border-l1:color-mix(in srgb,#8b7cf6 22%,#2a2547)!important}",
			"body.nxwatch-active.nxwatch-night:not([data-ds-dark-theme]){--dsw-alias-bg-base:#faf9fd!important;--dsw-alias-bg-layer-1:#f4f2fa!important;--dsw-alias-bg-layer-2:#edeaf7!important;--dsw-specific-sidebar-fill:#f6f4fb!important;--dsw-alias-border-l1:color-mix(in srgb,#8b7cf6 24%,#e3dcf3)!important}",
			// ── 状态条:玻璃胶囊 ──
			".nxw_dock{box-sizing:border-box;width:calc(100% - var(--dsh-composer-side-clearance)*2 - var(--dsh-composer-dock-inset)*2);max-width:calc(var(--dsh-composer-card-max-width) - var(--dsh-composer-dock-inset)*2);margin:0 auto;flex:none;border:1px solid color-mix(in srgb,var(--dsw-alias-border-l1) 60%,transparent);background:color-mix(in srgb,var(--dsw-alias-bg-layer-1) 62%,transparent);backdrop-filter:blur(14px) saturate(1.25);-webkit-backdrop-filter:blur(14px) saturate(1.25);border-radius:14px;padding:4px 10px;box-shadow:0 8px 24px rgba(93,72,208,0.10)}",
			".nxw_bar{min-height:30px;color:var(--dsw-alias-label-tertiary);align-items:center;gap:6px;font-size:12px;line-height:18px;display:flex;flex-wrap:wrap}",
			".nxw_mark{color:var(--dsw-alias-label-primary);font-weight:650;align-items:center;gap:6px;display:inline-flex;letter-spacing:.3px}",
			"@keyframes nxwPulse{0%,100%{box-shadow:0 0 0 0 rgba(139,124,246,0.45)}50%{box-shadow:0 0 0 4px rgba(139,124,246,0)}}",
			".nxw_mark .nxw_gem{width:8px;height:8px;border-radius:2px;background:linear-gradient(135deg,#8b7cf6,#4c8bd9);display:inline-block;animation:nxwPulse 3.2s ease-in-out infinite}",
			"@keyframes nxwBreath{0%,100%{opacity:1}50%{opacity:.35}}",
			".nxw_duty{color:#3aa98f;align-items:center;gap:4px;display:inline-flex}",
			".nxw_duty::before{content:'';width:6px;height:6px;border-radius:999px;background:#3aa98f;animation:nxwBreath 2.4s ease-in-out infinite}",
			".nxw_chip{border:1px solid var(--dsw-alias-border-l1);background:color-mix(in srgb,var(--dsw-specific-tip) 72%,transparent);backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px);border-radius:999px;align-items:center;gap:4px;padding:1px 9px;display:inline-flex;white-space:nowrap;transition:transform .2s ease,border-color .2s ease,background .2s ease}",
			".nxw_chip:hover{transform:translateY(-1px);border-color:color-mix(in srgb,#8b7cf6 45%,transparent);background:color-mix(in srgb,var(--dsw-specific-tip) 88%,#8b7cf6 8%)}",
			".nxw_dot{width:6px;height:6px;border-radius:999px;flex:none}",
			".nxw_dotF{background:#8b7cf6}.nxw_dotD{background:#d9a441}.nxw_dotA{background:#3aa98f}",
			".nxw_dotClean{background:var(--dsw-alias-state-success-primary)}.nxw_dotDirty{background:var(--dsw-alias-state-error-primary)}",
			".nxw_modeDanger{color:var(--dsw-alias-state-warn-primary)}",
			".nxw_spacer{flex:auto}",
			".nxw_btn{cursor:pointer;background:0 0;border:none;color:inherit;align-items:center;gap:4px;padding:1px 6px;display:inline-flex;transition:transform .2s ease,color .2s ease}",
			".nxw_btn:hover{color:var(--dsw-alias-label-primary);transform:translateY(-1px)}",
			// ── 值班室面板 ──
			".nxw_panel{position:relative;overflow:hidden;border:1px solid color-mix(in srgb,#8b7cf6 28%,var(--dsw-alias-border-l1));background:color-mix(in srgb,var(--dsw-alias-bg-layer-1) 66%,transparent);backdrop-filter:blur(16px) saturate(1.3);-webkit-backdrop-filter:blur(16px) saturate(1.3);border-radius:14px;margin-top:6px;padding:16px 18px;min-height:240px;box-shadow:0 12px 32px rgba(93,72,208,0.16);transition:border-color .3s ease,box-shadow .3s ease}",
			".nxw_panel:hover{border-color:color-mix(in srgb,#8b7cf6 55%,var(--dsw-alias-border-l1));box-shadow:0 16px 44px rgba(93,72,208,0.26)}",
			".nxw_bg{pointer-events:none;position:absolute;top:0;bottom:0;right:0;width:46%;opacity:.92;background:url('/plugins/nxwatch/assets/hero.png') no-repeat;background-size:auto 165%;background-position:72% center;-webkit-mask-image:linear-gradient(to right,transparent 0,#000 16%);mask-image:linear-gradient(to right,transparent 0,#000 16%);transition:transform .45s ease;will-change:transform}",
			".nxw_video{pointer-events:none;position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:.18;filter:saturate(.85)}",
			".nxw_scrim{pointer-events:none;position:absolute;inset:0;background:linear-gradient(to right,var(--dsw-alias-bg-layer-1) 0%,color-mix(in srgb,var(--dsw-alias-bg-layer-1) 55%,transparent) 52%,transparent 100%)}",
			".nxw_glow{pointer-events:none;position:absolute;inset:0;background:transparent;transition:background .35s ease}",
			".nxw_inner{position:relative;display:flex;flex-direction:column;gap:var(--nxw-gap,10px);max-width:56%}",
			".nxw_title{color:var(--dsw-alias-label-primary);font-size:15px;font-weight:650;align-items:baseline;gap:8px;display:flex;flex-wrap:wrap}",
			".nxw_motto{color:var(--dsw-alias-label-secondary);font-size:12px;line-height:18px}",
			// ── 三层护栏卡片 ──
			".nxw_cards{display:flex;flex-direction:column;gap:var(--nxw-gap,10px)}",
			".nxw_card{position:relative;border:1px solid var(--dsw-alias-border-l1);background:color-mix(in srgb,var(--dsw-alias-bg-layer-2) 52%,transparent);backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);border-radius:10px;padding:7px 10px 7px 12px;font-size:12px;line-height:18px;color:var(--dsw-alias-label-secondary);transition:transform .2s ease,border-color .2s ease,box-shadow .2s ease}",
			".nxw_card:hover{transform:translateX(3px);border-color:var(--nxw-accent,color-mix(in srgb,#8b7cf6 40%,var(--dsw-alias-border-l1)));box-shadow:0 4px 14px rgba(93,72,208,0.12)}",
			".nxw_card::before{content:'';position:absolute;left:0;top:8px;bottom:8px;width:3px;border-radius:3px;background:var(--nxw-accent,#8b7cf6)}",
			".nxw_cardF{--nxw-accent:#8b7cf6}.nxw_cardD{--nxw-accent:#d9a441}.nxw_cardA{--nxw-accent:#3aa98f}",
			".nxw_card b{color:var(--dsw-alias-label-primary);font-weight:600;margin-right:6px}",
			".nxw_card .nxw_mono{font-family:ui-monospace,var(--dsw-font-family);text-overflow:ellipsis;white-space:nowrap;overflow:hidden;display:block}",
			// ── 调音台(按需调整) ──
			".nxw_mixer{border:1px dashed color-mix(in srgb,#8b7cf6 35%,var(--dsw-alias-border-l1));border-radius:10px;padding:8px 12px;display:flex;flex-direction:column;gap:6px}",
			".nxw_mixRow{display:flex;align-items:center;gap:10px;font-size:12px;line-height:18px;color:var(--dsw-alias-label-secondary)}",
			".nxw_mixRow label{flex:none;min-width:86px;color:var(--dsw-alias-label-primary)}",
			".nxw_mixRow input[type=range]{flex:1;accent-color:#8b7cf6;height:16px}",
			".nxw_mixRow .nxw_val{flex:none;min-width:34px;text-align:right;font-variant-numeric:tabular-nums}",
			".nxw_switch{cursor:pointer;position:relative;width:30px;height:17px;border-radius:999px;border:none;background:var(--dsw-alias-state-warn-primary);transition:background .2s ease;flex:none}",
			".nxw_switch::after{content:'';position:absolute;top:2px;left:2px;width:13px;height:13px;border-radius:999px;background:#fff;transition:transform .2s ease}",
			".nxw_switch[data-on=true]{background:#8b7cf6}.nxw_switch[data-on=true]::after{transform:translateX(13px)}",
			".nxw_rule{margin-top:2px;display:flex;gap:16px;flex-wrap:wrap;align-items:center}",
			".nxw_ambient{margin-left:auto}",
			// ── 首页大厅:夜间值守站(破坏性重设计,空白会话全屏卡片) ──
			".nxw_lobby{box-sizing:border-box;width:calc(100% - var(--dsh-composer-side-clearance)*2);max-width:calc(var(--dsh-composer-card-max-width) + 2*var(--dsh-composer-side-clearance));margin:0 auto;flex:none}",
			".nxw_lobbyCard{position:relative;overflow:hidden;border:1px solid color-mix(in srgb,#8b7cf6 32%,var(--dsw-alias-border-l1));background:color-mix(in srgb,var(--dsw-alias-bg-layer-1) 72%,transparent);backdrop-filter:blur(18px) saturate(1.3);-webkit-backdrop-filter:blur(18px) saturate(1.3);border-radius:20px;padding:30px 26px 24px;text-align:center;box-shadow:0 18px 50px rgba(93,72,208,0.20)}",
			".nxw_lobbyAurora{pointer-events:none;position:absolute;inset:0;background:radial-gradient(ellipse 90% 55% at 50% -18%,rgba(139,124,246,0.22),transparent 62%),radial-gradient(ellipse 60% 45% at 88% 105%,rgba(76,139,217,0.18),transparent 65%);animation:nxwLobbyGlow 9s ease-in-out infinite alternate}",
			"@keyframes nxwLobbyGlow{from{opacity:.75}to{opacity:1}}",
			".nxw_lobbyInner{position:relative}",
			".nxw_lobbyKicker{color:var(--dsw-alias-label-tertiary);font-size:11px;letter-spacing:2.5px;text-transform:uppercase}",
			".nxw_lobbyTitle{font-size:34px;font-weight:800;line-height:1.15;margin-top:6px;background:linear-gradient(100deg,#8b7cf6 10%,#6f9df0 45%,#3aa98f 90%);-webkit-background-clip:text;background-clip:text;color:transparent;letter-spacing:1px}",
			".nxw_lobbySub{color:var(--dsw-alias-label-secondary);font-size:13px;line-height:20px;margin-top:8px}",
			".nxw_lobbyCards{display:flex;gap:10px;justify-content:center;margin:18px 0 6px;flex-wrap:wrap}",
			".nxw_lobbyCardSmall{text-align:left;border:1px solid var(--dsw-alias-border-l1);background:color-mix(in srgb,var(--dsw-alias-bg-layer-2) 60%,transparent);border-radius:12px;padding:10px 14px;min-width:150px;flex:1;max-width:220px;position:relative;overflow:hidden}",
			".nxw_lobbyCardSmall::before{content:'';position:absolute;left:0;top:10px;bottom:10px;width:3px;border-radius:3px;background:var(--nxw-accent,#8b7cf6)}",
			".nxw_lobbyCardSmall b{display:block;color:var(--dsw-alias-label-primary);font-size:13px;font-weight:650;margin-bottom:3px}",
			".nxw_lobbyCardSmall span{color:var(--dsw-alias-label-tertiary);font-size:11px;line-height:16px;display:block}",
			".nxw_presetRow{display:flex;gap:8px;justify-content:center;flex-wrap:wrap;margin-top:14px}",
			".nxw_presetPill{cursor:pointer;border:1px solid var(--dsw-alias-border-l1);background:color-mix(in srgb,var(--dsw-specific-tip) 70%,transparent);border-radius:999px;padding:4px 14px;font-size:12px;color:var(--dsw-alias-label-secondary);transition:all .2s ease}",
			".nxw_presetPill:hover{transform:translateY(-1px);border-color:color-mix(in srgb,#8b7cf6 50%,transparent)}",
			".nxw_presetPill[data-active=true]{color:#fff;border-color:transparent;background:linear-gradient(120deg,#7d6cf0,#5b8fd9);font-weight:600;box-shadow:0 4px 14px rgba(125,108,240,0.35)}",
			".nxw_lobbyCwd{color:var(--dsw-alias-label-tertiary);font-size:11px;margin-top:10px;font-family:ui-monospace,var(--dsw-font-family)}",
			".nxw_lobbyCta{margin-top:16px;cursor:pointer;border:none;border-radius:999px;padding:8px 22px;font-size:13px;font-weight:650;color:#fff;background:linear-gradient(120deg,#7d6cf0,#5b8fd9);box-shadow:0 8px 20px rgba(125,108,240,0.35);transition:transform .2s ease,box-shadow .2s ease}",
			".nxw_lobbyCta:hover{transform:translateY(-1px);box-shadow:0 12px 26px rgba(125,108,240,0.45)}",
			".nxw_lobbyErr{color:var(--dsw-alias-state-error-primary);font-size:11px;margin-top:8px}",
			".nxw_lobbyReopen{box-sizing:border-box;width:calc(100% - var(--dsh-composer-side-clearance)*2);max-width:calc(var(--dsh-composer-card-max-width) + 2*var(--dsh-composer-side-clearance));margin:0 auto 8px;display:flex;justify-content:center}",
			".nxw_lobbyReopen button{cursor:pointer;border:1px solid color-mix(in srgb,#8b7cf6 35%,var(--dsw-alias-border-l1));background:color-mix(in srgb,var(--dsw-alias-bg-layer-1) 70%,transparent);border-radius:999px;padding:3px 14px;font-size:11px;color:var(--dsw-alias-label-secondary)}",
			// ── 主题强调色(守夜人会话) ──
			"body.nxwatch-active{--dsw-alias-brand-primary:#7d6cf0!important;--dsw-alias-state-business-primary:#7d6cf0!important}",
			"body.nxwatch-active[data-ds-dark-theme]{--dsw-alias-brand-primary:#a89df7!important;--dsw-alias-state-business-primary:#a89df7!important}",
			// ── 动效尊重系统设置 ──
			"@media (prefers-reduced-motion: reduce){body.nxwatch-active.nxwatch-aurora::after,.nxw_gem,.nxw_duty::before{animation:none!important}.nxw_bg{transition:none!important}}",
		].join("\n");
		const STYLE_KEY = "nxwatch/style-v4";
		if (typeof document !== "undefined" && document.querySelector(`style[data-plugin-css="${STYLE_KEY}"]`) === null) {
			const tag = document.createElement("style");
			tag.dataset.plugin = "nxwatch";
			tag.dataset.pluginCss = STYLE_KEY;
			tag.textContent = css;
			document.head.appendChild(tag);
		}
		//#endregion
		const jsx = react_jsx_runtime.jsx;
		const jsxs = react_jsx_runtime.jsxs;
		const { useState, useEffect, useCallback, useRef } = react;

		// ── 守夜铃:回合结束/等待用户时的 3 秒提示音(Web Audio 现场合成) ──
		let audioCtx = null;
		let chimeVolume = 0.7;
		function setChimeVolume(v) { chimeVolume = v; }
		function ensureAudio() {
			if (audioCtx === null && typeof window !== "undefined") {
				const Ctor = window.AudioContext ?? window.webkitAudioContext;
				if (Ctor !== undefined) audioCtx = new Ctor();
			}
			if (audioCtx !== null && audioCtx.state === "suspended") {
				audioCtx.resume().catch(() => {});
			}
			return audioCtx;
		}
		function bell(ctx, when, freq, gain, duration) {
			const osc = ctx.createOscillator();
			const osc2 = ctx.createOscillator();
			const partial = ctx.createOscillator();
			const env = ctx.createGain();
			const partialGain = ctx.createGain();
			const g = gain * chimeVolume;
			osc.type = "sine";
			osc.frequency.value = freq;
			osc2.type = "triangle";
			osc2.frequency.value = freq;
			osc2.detune.value = 3;
			partial.type = "sine";
			partial.frequency.value = freq * 2.71;
			partialGain.gain.value = 0.18;
			env.gain.setValueAtTime(0.0001, when);
			env.gain.exponentialRampToValueAtTime(g, when + 0.012);
			env.gain.exponentialRampToValueAtTime(0.0001, when + duration);
			osc.connect(env);
			osc2.connect(env);
			partial.connect(partialGain);
			partialGain.connect(env);
			env.connect(ctx.destination);
			osc.start(when);
			osc.stop(when + duration + 0.05);
			osc2.start(when);
			osc2.stop(when + duration + 0.05);
			partial.start(when);
			partial.stop(when + duration + 0.05);
		}
		function playChime() {
			const ctx = ensureAudio();
			if (ctx === null) return;
			const t0 = ctx.currentTime + 0.03;
			const notes = [
				[554.37, 0.00, 0.9, 0.16], // C#5
				[659.25, 0.16, 0.9, 0.15], // E5
				[830.61, 0.32, 0.9, 0.13], // G#5
				[880.00, 0.48, 1.0, 0.12], // A5
				[1318.51, 0.74, 1.3, 0.07], // E6 星点
			];
			for (const [freq, at, dur, gain] of notes) bell(ctx, t0 + at, freq, gain, dur);
			const drone = ctx.createOscillator();
			const droneEnv = ctx.createGain();
			drone.type = "sine";
			drone.frequency.value = 220;
			droneEnv.gain.setValueAtTime(0.0001, t0 + 1.0);
			droneEnv.gain.exponentialRampToValueAtTime(0.05 * chimeVolume, t0 + 1.25);
			droneEnv.gain.exponentialRampToValueAtTime(0.0001, t0 + 3.0);
			drone.connect(droneEnv);
			droneEnv.connect(ctx.destination);
			drone.start(t0 + 1.0);
			drone.stop(t0 + 3.1);
		}

		// 从会话历史中解析最近的运行时上下文快照(文件策略 + 审批策略)。
		function parsePolicy(events) {
			if (!Array.isArray(events)) return null;
			for (let i = events.length - 1; i >= 0; i--) {
				const event = events[i];
				if (event?.type !== "user/message") continue;
				const content = event?.data?.content;
				if (!Array.isArray(content)) continue;
				for (const block of content) {
					if (block?.type !== "text" || typeof block.text !== "string") continue;
					if (!block.text.startsWith("Current runtime context.")) continue;
					const modeMatch = /Current DSH file policy: (\S+)/.exec(block.text);
					const approvalDisabled = block.text.includes("Approval prompts are disabled in this session");
					const approvalAsk = block.text.includes('Approval policy: ask');
					return {
						mode: modeMatch?.[1] ?? null,
						approval: approvalDisabled ? "never" : approvalAsk ? "ask" : null,
					};
				}
			}
			return null;
		}

		const DEFAULT_SETTINGS = { aurora: 70, night: true, video: false, sound: true, volume: 70, density: "standard", parallax: true };
		function loadSettings() {
			try {
				const raw = window.localStorage.getItem("nxwatch.settings");
				if (raw === null) return DEFAULT_SETTINGS;
				return { ...DEFAULT_SETTINGS, ...JSON.parse(raw) };
			} catch {
				return DEFAULT_SETTINGS;
			}
		}

		function NightWatchDock({ sessionId, useSessions, useSession, api }) {
			const preset = useSessions !== undefined
				? useSessions((s) => s?.byId?.[sessionId]?.agentPreset)
				: undefined;
			const running = useSession !== undefined ? useSession((s) => s?.running) : undefined;
			const [meta, setMeta] = useState(null);
			const [policy, setPolicy] = useState(null);
			const [expanded, setExpanded] = useState(false);
			const [mixerOpen, setMixerOpen] = useState(false);
			const [settings, setSettings] = useState(loadSettings);
			const prevRunning = useRef(undefined);
			const settingsRef = useRef(settings);
			const panelRef = useRef(null);
			const bgRef = useRef(null);
			const glowRef = useRef(null);
			settingsRef.current = settings;

			// 设置落地:持久化 + 全局效果(底色/极光/音量)。
			useEffect(() => {
				try { window.localStorage.setItem("nxwatch.settings", JSON.stringify(settings)); } catch { /* 无痕模式忽略 */ }
				setChimeVolume(settings.volume / 100);
			}, [settings]);
			useEffect(() => {
				document.body.classList.toggle("nxwatch-night", settings.night);
				document.body.classList.toggle("nxwatch-aurora", settings.aurora > 0);
				document.body.style.setProperty("--nxw-aurora", String(settings.aurora / 100));
			}, [settings.night, settings.aurora]);

			// 浏览器自动播放唤醒(极光已改为纯 CSS body::after,无需 JS 挂载)。
			useEffect(() => {
				const wake = () => { if (settingsRef.current.sound) ensureAudio(); };
				window.addEventListener("pointerdown", wake, { capture: true });
				window.addEventListener("keydown", wake, { capture: true });
				return () => {
					window.removeEventListener("pointerdown", wake, { capture: true });
					window.removeEventListener("keydown", wake, { capture: true });
				};
			}, []);

			// 落子音:running true→false 即"回合结束/等待用户",播 3 秒守夜铃(仅守夜人会话)。
			useEffect(() => {
				if (running === undefined) return;
				if (prevRunning.current === true && running === false && preset === "nixos-guard") {
					if (settingsRef.current.sound) playChime();
				}
				prevRunning.current = running;
			}, [running, preset]);

			useEffect(() => {
				let alive = true;
				const load = () => {
					fetch("/plugins/nxwatch/meta")
						.then((r) => r.json())
						.then((m) => { if (alive && m?.ok) setMeta(m); })
						.catch(() => {});
				};
				load();
				const timer = setInterval(load, 60000);
				return () => { alive = false; clearInterval(timer); };
			}, []);

			useEffect(() => {
				if (sessionId === undefined || api?.sessions?.history === undefined) return;
				let alive = true;
				const load = async () => {
					try {
						const r = await api.sessions.history({ sessionId, maxMessages: 200 });
						if (!alive) return;
						const events = r?.result?.ok ? r.result.value.events : undefined;
						setPolicy(parsePolicy(events ?? []));
					} catch { /* 保持上一条 */ }
				};
				load();
				const timer = setInterval(load, 30000);
				return () => { alive = false; clearInterval(timer); };
			}, [sessionId, api]);

			useEffect(() => {
				if (preset !== "nixos-guard") return;
				document.body.classList.add("nxwatch-active");
				return () => document.body.classList.remove("nxwatch-active");
			}, [preset]);

			const toggle = useCallback(() => setExpanded((v) => !v), []);
			const toggleMixer = useCallback(() => setMixerOpen((v) => !v), []);
			const patch = useCallback((part) => setSettings((s) => ({ ...s, ...part })), []);
			const toggleSound = useCallback(() => {
				setSettings((s) => {
					const next = { ...s, sound: !s.sound };
					if (next.sound) playChime(); // 开启时即时试听
					return next;
				});
			}, []);

			// 鼠标交互:立绘视差 + 光标追光(视差可关)。
			const onPanelMove = useCallback((event) => {
				const panel = panelRef.current;
				if (panel === null) return;
				const rect = panel.getBoundingClientRect();
				const px = (event.clientX - rect.left) / rect.width - 0.5;
				const py = (event.clientY - rect.top) / rect.height - 0.5;
				if (settingsRef.current.parallax) {
					const bg = bgRef.current;
					if (bg !== null) {
						bg.style.transition = "none";
						bg.style.transform = `translate3d(${(-px * 12).toFixed(1)}px, ${(-py * 9).toFixed(1)}px, 0) scale(1.03)`;
					}
				}
				const glow = glowRef.current;
				if (glow !== null) {
					glow.style.background = `radial-gradient(280px circle at ${(event.clientX - rect.left).toFixed(0)}px ${(event.clientY - rect.top).toFixed(0)}px, rgba(139,124,246,0.13), transparent 70%)`;
				}
			}, []);
			const onPanelLeave = useCallback(() => {
				const bg = bgRef.current;
				if (bg !== null) {
					bg.style.transition = "transform .45s ease";
					bg.style.transform = "translate3d(0,0,0) scale(1)";
				}
				const glow = glowRef.current;
				if (glow !== null) glow.style.background = "transparent";
			}, []);

			if (preset !== "nixos-guard") return null;

			const git = meta?.git;
			const gitClean = git?.ok === true && git.dirty === 0;
			const mode = policy?.mode ?? meta?.defaultSandboxMode ?? "unknown";
			const modeDanger = mode === "danger-full-access";
			const approval = policy?.approval;
			const hasApproval = approval !== null && approval !== undefined && approval !== "";
			const gitTitle = git?.ok === true && git.dirtyFiles !== undefined && git.dirtyFiles.length > 0
				? "未提交:\n" + git.dirtyFiles.join("\n")
				: undefined;
			const densityGap = settings.density === "compact" ? "6px" : settings.density === "comfy" ? "16px" : "10px";

			const bar = jsxs("div", { className: "nxw_bar", children: [
				jsxs("span", { className: "nxw_mark", children: [
					jsx("span", { className: "nxw_gem" }),
					"守夜人",
				] }),
				jsx("span", { className: "nxw_duty", children: "值守中" }),
				jsxs("span", { className: "nxw_chip", title: "FENCE 围栏 · 宿主沙箱与审批", children: [
					jsx("span", { className: "nxw_dot nxw_dotF" }), "FENCE",
				] }),
				jsxs("span", { className: "nxw_chip", title: "DISCIPLINE 纪律 · 守衡协议", children: [
					jsx("span", { className: "nxw_dot nxw_dotD" }), "DISCIPLINE",
				] }),
				jsxs("span", { className: "nxw_chip", title: "AUDIT 审计 · 会话日志 + git", children: [
					jsx("span", { className: "nxw_dot nxw_dotA" }), "AUDIT",
				] }),
				jsxs("span", {
					className: "nxw_chip",
					title: gitTitle,
					children: [
						jsx("span", { className: gitClean ? "nxw_dot nxw_dotClean" : "nxw_dot nxw_dotDirty" }),
						git?.ok === true ? `nixos ${git.branch} ${git.lastCommit}` : "nixos git ·",
					],
				}),
				jsxs("span", {
					className: "nxw_chip" + (modeDanger ? " nxw_modeDanger" : ""),
					title: hasApproval ? `approval: ${approval}` : "会话策略见运行时上下文",
					children: [
						mode,
						hasApproval ? ` · ${approval}` : null,
					],
				}),
				jsx("span", { className: "nxw_spacer" }),
				jsxs("button", {
					type: "button",
					className: "nxw_btn",
					title: "外观与音效(按需调整)",
					"aria-expanded": mixerOpen,
					onClick: toggleMixer,
					children: ["⚙"],
				}),
				jsxs("button", {
					type: "button",
					className: "nxw_btn",
					title: settings.sound ? "回合结束时播放 3 秒守夜铃" : "落子音已关闭",
					onClick: toggleSound,
					children: [settings.sound ? "🔔" : "🔕"],
				}),
				jsxs("button", { type: "button", className: "nxw_btn", onClick: toggle, "aria-expanded": expanded, children: [
					expanded ? "收起 ▴" : "值班室 ▾",
				] }),
			] });

			const mixer = mixerOpen ? jsxs("div", { className: "nxw_mixer", children: [
				jsxs("div", { className: "nxw_mixRow", children: [
					jsx("label", { children: "极光强度" }),
					jsx("input", {
						type: "range", min: 0, max: 100, value: settings.aurora,
						"aria-label": "极光强度",
						onChange: (e) => patch({ aurora: Number(e.target.value) }),
					}),
					jsx("span", { className: "nxw_val", children: `${settings.aurora}%` }),
				] }),
				jsxs("div", { className: "nxw_mixRow", children: [
					jsx("label", { children: "夜色底色" }),
					jsx("button", { type: "button", className: "nxw_switch", "data-on": String(settings.night), "aria-pressed": settings.night, onClick: () => patch({ night: !settings.night }) }),
					jsx("span", { className: "nxw_motto", children: "整页深靛/薰衣草底" }),
				] }),
				jsxs("div", { className: "nxw_mixRow", children: [
					jsx("label", { children: "动态壁纸" }),
					jsx("button", { type: "button", className: "nxw_switch", "data-on": String(settings.video), "aria-pressed": settings.video, onClick: () => patch({ video: !settings.video }) }),
					jsx("span", { className: "nxw_motto", children: "魔女之旅 · 静音循环" }),
				] }),
				jsxs("div", { className: "nxw_mixRow", children: [
					jsx("label", { children: "落子音" }),
					jsx("button", { type: "button", className: "nxw_switch", "data-on": String(settings.sound), "aria-pressed": settings.sound, onClick: toggleSound }),
					jsx("span", { className: "nxw_motto", children: "回合结束响 3 秒守夜铃" }),
				] }),
				jsxs("div", { className: "nxw_mixRow", children: [
					jsx("label", { children: "铃声音量" }),
					jsx("input", {
						type: "range", min: 10, max: 100, value: settings.volume,
						"aria-label": "铃声音量",
						onChange: (e) => patch({ volume: Number(e.target.value) }),
					}),
					jsx("span", { className: "nxw_val", children: `${settings.volume}%` }),
				] }),
				jsxs("div", { className: "nxw_mixRow", children: [
					jsx("label", { children: "卡片密度" }),
					jsxs("span", { className: "nxw_chip", children: [
						["compact", "standard", "comfy"].map((d) => {
							const names = { compact: "紧凑", standard: "标准", comfy: "舒展" };
							return jsx("button", {
								type: "button", key: d, className: "nxw_btn",
								style: { fontWeight: settings.density === d ? 650 : 400, color: settings.density === d ? "var(--dsw-alias-label-primary)" : "inherit" },
								onClick: () => patch({ density: d }),
								children: [names[d]],
							});
						}),
					] }),
				] }),
				jsxs("div", { className: "nxw_mixRow", children: [
					jsx("label", { children: "立绘视差" }),
					jsx("button", { type: "button", className: "nxw_switch", "data-on": String(settings.parallax), "aria-pressed": settings.parallax, onClick: () => patch({ parallax: !settings.parallax }) }),
					jsx("span", { className: "nxw_motto", children: "光标带动立绘漂移" }),
				] }),
			] }) : null;

			const panel = expanded ? jsxs("div", {
				className: "nxw_panel",
				ref: panelRef,
				style: { "--nxw-gap": densityGap },
				onPointerMove: onPanelMove,
				onPointerLeave: onPanelLeave,
				children: [
					settings.video
						? jsx("video", { className: "nxw_video", src: "/plugins/nxwatch/ambient.mp4", autoPlay: true, muted: true, loop: true, playsInline: true })
						: jsx("div", { className: "nxw_bg", ref: bgRef }),
					jsx("div", { className: "nxw_glow", ref: glowRef }),
					jsx("div", { className: "nxw_scrim" }),
					jsxs("div", { className: "nxw_inner", children: [
						jsxs("div", { className: "nxw_title", children: [
							"NixOS 守夜人",
							jsx("span", { className: "nxw_duty", children: "值守中" }),
							jsx("span", { className: "nxw_motto", children: "围栏给空间 · 纪律给顺序 · 审计给记忆" }),
						] }),
						jsxs("div", { className: "nxw_cards", children: [
							jsxs("div", { className: "nxw_card nxw_cardF", children: [
								jsx("b", { children: "FENCE" }),
								"会话策略:",
								mode,
								hasApproval ? ` / 审批 ${approval}` : "",
								" · 宿主默认:",
								meta?.defaultSandboxMode ?? "…",
							] }),
							jsxs("div", { className: "nxw_card nxw_cardD", children: [
								jsx("b", { children: "DISCIPLINE" }),
								"test 先行 → 验证后重试 → 网络显式 → 密钥不落地",
							] }),
							jsxs("div", { className: "nxw_card nxw_cardA", children: [
								jsx("b", { children: "AUDIT" }),
								"git:",
								git?.ok === true ? `${git.branch} · ${git.lastCommit} · ${git.dirty} 个未提交` : "读取失败",
								" · ",
								meta?.hostname ?? "…",
								jsx("span", { className: "nxw_mono", children: "subagent_lite → deepseek-v4-flash(杂活) · subagent/fork → 继承路由(重活)" }),
							] }),
						] }),
						mixer,
						jsxs("div", { className: "nxw_rule", children: [
							jsx("span", { className: "nxw_motto", children: "协议全文:`skill(nixos-guard-protocol)` · 外层围栏:`modules/services/dsh-fence.nix`" }),
							jsxs("button", { type: "button", className: "nxw_btn nxw_ambient", onClick: () => patch({ video: !settings.video }), children: [
								settings.video ? "⏸ 关闭壁纸" : "▶ 动态壁纸",
							] }),
						] }),
					] }),
				],
			}) : null;

			return jsxs("section", { className: "nxw_dock", "data-testid": "nxwatch-dock", children: [bar, panel] });
		}

		// ── 首页大厅:夜间值守站(破坏性重设计,空白会话全屏卡片) ──
		function NightWatchLobby({ sessionId, useSessions, api }) {
			const preset = useSessions !== undefined ? useSessions((s) => s?.byId?.[sessionId]?.agentPreset) : undefined;
			const blank = useSessions !== undefined ? useSessions((s) => s?.byId?.[sessionId]?.blank) : undefined;
			const cwd = useSessions !== undefined ? useSessions((s) => s?.byId?.[sessionId]?.cwd) : undefined;
			const [presets, setPresets] = useState(null);
			const [busy, setBusy] = useState(false);
			const [error, setError] = useState(null);
			const [dismissed, setDismissed] = useState(() => {
				try { return sessionId !== undefined && window.sessionStorage.getItem(`nxw.lobby.${sessionId}`) === "1"; }
				catch { return false; }
			});

			useEffect(() => {
				if (api?.agentPresets?.list === undefined) return;
				let alive = true;
				api.agentPresets.list({}).then((r) => {
					if (!alive) return;
					if (r?.result?.ok) setPresets((r.result.value.presets ?? []).filter((p) => p.broken === void 0));
				}).catch(() => { if (alive) setError("预设列表读取失败"); });
				return () => { alive = false; };
			}, [api]);

			if (blank !== true) return null;

			const dismiss = () => {
				try { if (sessionId !== undefined) window.sessionStorage.setItem(`nxw.lobby.${sessionId}`, "1"); }
				catch { /* 无痕模式忽略 */ }
				setDismissed(true);
			};
			if (dismissed) {
				return jsx("div", { className: "nxw_lobbyReopen", children: jsx("button", {
					type: "button",
					onClick: () => setDismissed(false),
					children: "⌂ 值守站",
				}) });
			}
			const pick = (id) => {
				if (busy || sessionId === undefined) return;
				setBusy(true);
				setError(null);
				api?.agentPresets?.select?.({ sessionId, agentPreset: id }).then((r) => {
					setBusy(false);
					if (r?.result?.ok !== true) setError(r?.result?.error?.message ?? "切换失败");
				}).catch((e) => { setBusy(false); setError(e?.message ?? "切换失败"); });
			};
			const layers = [
				{ cls: "nxw_cardF", title: "FENCE · 围栏", text: "宿主沙箱与审批;本预设从不越层,拒绝即终局。" },
				{ cls: "nxw_cardD", title: "DISCIPLINE · 纪律", text: "test 先行 → 验证后重试;网络显式,密钥不落地。" },
				{ cls: "nxw_cardA", title: "AUDIT · 审计", text: "事件日志 + git 留痕,每一次触碰都有账可查。" },
			];
			return jsxs("section", { className: "nxw_lobby", "data-testid": "nxwatch-lobby", children: [
				jsxs("div", { className: "nxw_lobbyCard", children: [
					jsx("div", { className: "nxw_lobbyAurora" }),
					jsxs("div", { className: "nxw_lobbyInner", children: [
						jsx("div", { className: "nxw_lobbyKicker", children: "NIGHT WATCH · 夜间值守站" }),
						jsx("div", { className: "nxw_lobbyTitle", children: "NIXOS 守夜人" }),
						jsx("div", { className: "nxw_lobbySub", children: "围栏给空间 · 纪律给顺序 · 审计给记忆" }),
						jsxs("div", { className: "nxw_lobbyCards", children: layers.map((l) => jsxs("div", {
							key: l.cls,
							className: `nxw_lobbyCardSmall ${l.cls}`,
							children: [jsx("b", { children: l.title }), jsx("span", { children: l.text })],
						})) }),
						jsx("div", { className: "nxw_lobbyCwd", children: `工作区 ${cwd ?? "…"}` }),
						jsxs("div", { className: "nxw_presetRow", children: (presets ?? []).map((p) => jsx("button", {
							type: "button",
							key: p.id,
							className: "nxw_presetPill",
							"data-active": String(p.id === preset),
							disabled: busy,
							onClick: () => pick(p.id),
							children: p.name ?? p.id,
						})) }),
						error !== null ? jsx("div", { className: "nxw_lobbyErr", children: error }) : null,
						jsx("div", { children: jsx("button", {
							type: "button",
							className: "nxw_lobbyCta",
							onClick: dismiss,
							children: "开始值守 →",
						}) }),
					] }),
				] }),
			] });
		}

		function apply(ctx) {
			const connection = ctx.get("connection");
			const api = connection?.api;
			ctx.slots.inject("conversation.composer.dock", () => ctx.slots.register({
				name: "conversation.composer.dock",
				id: "nxwatch",
				order: 200,
				inject: (sessionId) => ({ sessionId, api }),
			}, NightWatchDock));
			// 首页大厅:input.dock 无 hero 守卫,空白会话也渲染,全屏卡片式值守站。
			ctx.slots.inject("conversation.input.dock", () => ctx.slots.register({
				name: "conversation.input.dock",
				id: "nxwatch-lobby",
				order: 100,
				inject: (sessionId) => ({ sessionId, api }),
			}, NightWatchLobby));
			// 遮蔽出厂预设 chip:预设选择由大厅接管。
		ctx.slots.inject("conversation.hero.agentPreset", () => ctx.slots.register({
			name: "conversation.hero.agentPreset",
			priority: -100,
			inject: () => ({}),
		}, () => null));
		}

		exports.apply = apply;
		exports.inject = ["slots"];
		return module.exports;
	}
});
