/**
 * Context progress widget for the OpenCode V2 session sidebar.
 *
 * Faithful port of @streetturtle/opencode-context-progress 1.0.2 (V1 API)
 * to the V2 plugin API (Plugin.define + ui.slot). Renders identically:
 *
 *   Context            (bold)
 *   ██████████░░░░░░░░ 42%
 *   84,000 / 200,000 / $1.23
 *
 * Original logic preserved: token count = input + output + reasoning +
 * cache.read + cache.write of the last assistant message; context window
 * from the active model; bar color = accent, warning >= 70%, error >= 90%.
 * V2 token mapping (v2.0.12 names): text→text.base, textMuted→text.muted,
 * accent→hue.accent[200], warning/error→text.feedback.*.base.
 */
/** @jsxImportSource @opentui/solid */
import { createMemo } from "solid-js"
import { Plugin, type Plugin as PluginTypes } from "@opencode/plugin/tui"
import { TextAttributes } from "@opentui/core"

const BAR_WIDTH = 24

function formatInt(value: number): string {
	return new Intl.NumberFormat("en-US").format(Math.max(0, Math.round(value)))
}

function formatMoney(value: number): string {
	return `$${value.toFixed(2)}`
}

function safeNumber(value: unknown): number {
	return typeof value === "number" && Number.isFinite(value) ? value : 0
}

function readCost(source: any): number {
	const candidates = [source?.cost, source?.info?.cost, source?.usage?.cost, source?.metrics?.cost]
	for (const c of candidates) {
		const n = typeof c === "number" ? c : typeof c === "string" && c !== "" ? Number(c) : NaN
		if (Number.isFinite(n) && n > 0) return n
	}
	return 0
}

function messageTokenCount(message: any): number {
	const input = safeNumber(message?.tokens?.input)
	const output = safeNumber(message?.tokens?.output)
	const reasoning = safeNumber(message?.tokens?.reasoning)
	const cacheRead = safeNumber(message?.tokens?.cache?.read)
	const cacheWrite = safeNumber(message?.tokens?.cache?.write)
	return input + output + reasoning + cacheRead + cacheWrite
}

function buildBar(percent: number): { bar: string; clamped: number } {
	const clamped = Math.max(0, Math.min(100, percent))
	const filled = Math.max(0, Math.min(BAR_WIDTH, Math.round((clamped / 100) * BAR_WIDTH)))
	return {
		bar: `${"█".repeat(filled)}${"░".repeat(BAR_WIDTH - filled)}`,
		clamped,
	}
}

function View(props: { context: PluginTypes.Context; sessionID: string }) {
	// v2.0.12 renamed theme tokens (default→base, subdued→muted,
	// feedback.default→feedback.base) and removed text.status. Read through
	// optional chaining with catppuccin hex fallbacks so a future rename
	// degrades to theme colors instead of crashing the slot.
	const t = () => props.context.theme as any
	const textBase = () => t()?.text?.base ?? "#cdd6f4"
	const textMuted = () => t()?.text?.muted ?? "#9399b2"
	const errorColor = () => t()?.text?.feedback?.error?.base ?? "#f38ba8"
	const warningColor = () => t()?.text?.feedback?.warning?.base ?? "#f9e2af"
	const accentColor = () => t()?.hue?.accent?.[200] ?? "#f5c2e7"
	const messages = createMemo(() => (props.context.data.session.message.list(props.sessionID) ?? []) as any[])
	const sessionCost = createMemo(() => {
		const fromState = readCost(props.context.data.session.get(props.sessionID) as any)
		if (fromState > 0) return fromState
		return messages()
			.filter((m: any) => ((m?.type ?? m?.role ?? m?.info?.role)) === "assistant")
			.reduce((sum, m) => sum + readCost(m), 0)
	})

	const usage = createMemo(() => {
		// V2 SessionMessageInfo: role lives in `type` (V1 used `role`/`info.role`).
		const lastAssistant = messages().findLast((m: any) => {
			const role = m?.type ?? m?.role ?? m?.info?.role
			const output = safeNumber(m?.tokens?.output)
			return role === "assistant" && output > 0
		})

		if (!lastAssistant) {
			return {
				tokens: 0,
				contextWindow: 0,
				percent: 0,
			}
		}

		const tokens = messageTokenCount(lastAssistant)
		const providerID =
			lastAssistant?.model?.providerID ?? lastAssistant?.providerID ?? lastAssistant?.info?.providerID
		const modelID = lastAssistant?.model?.id ?? lastAssistant?.modelID ?? lastAssistant?.info?.modelID
		const session = props.context.data.session.get(props.sessionID)
		const model = props.context.data.location.model
			.list(session?.location)
			?.find((item) => item.providerID === providerID && item.id === modelID)
		const contextWindow = safeNumber(model?.limit?.context)
		const percent = contextWindow > 0 ? Math.round((tokens / contextWindow) * 100) : 0

		return {
			tokens,
			contextWindow,
			percent,
		}
	})

	const detailLine = createMemo(() => {
		const state = usage()
		const limitText = state.contextWindow > 0 ? formatInt(state.contextWindow) : "--"
		return `${formatInt(state.tokens)} / ${limitText} / ${formatMoney(sessionCost())}`
	})

	const progress = createMemo(() => {
		const percent = usage().percent
		const bar = buildBar(percent)
		const color = percent >= 90 ? errorColor() : percent >= 70 ? warningColor() : accentColor()
		return {
			bar: bar.bar,
			color,
			percent: bar.clamped,
		}
	})

	return (
		<box>
			<text fg={textBase()} attributes={TextAttributes.BOLD}>
				Context
			</text>
			<box flexDirection="row" gap={1}>
				<text fg={progress().color}>{progress().bar}</text>
				<text fg={progress().color}> {progress().percent}%</text>
			</box>
			<text fg={textMuted()}>{detailLine()}</text>
		</box>
	)
}

export default Plugin.define({
	id: "local.context-progress",
	setup(context) {
		context.ui.slot({
			append: "sidebar.content",
			render: (props) => <View context={context} sessionID={props.sessionID} />,
		})
	},
})
