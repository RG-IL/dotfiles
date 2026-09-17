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
 * V2 token mapping: text→text.default, textMuted→text.subdued,
 * accent→text.status.unread (accent hue), warning/error→text.feedback.
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
	const messages = createMemo(() => (props.context.data.session.message.list(props.sessionID) ?? []) as any[])
	const sessionCost = createMemo(() => {
		const fromState = readCost(props.context.data.session.get(props.sessionID) as any)
		if (fromState > 0) return fromState
		return messages()
			.filter((m) => (m?.role ?? m?.info?.role) === "assistant")
			.reduce((sum, m) => sum + readCost(m), 0)
	})

	const usage = createMemo(() => {
		const lastAssistant = messages().findLast((m) => {
			const role = m?.role ?? m?.info?.role
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

	const theme = () => props.context.theme

	const progress = createMemo(() => {
		const percent = usage().percent
		const bar = buildBar(percent)
		const feedback = theme().text.feedback
		const color = percent >= 90 ? feedback.error.default : percent >= 70 ? feedback.warning.default : theme().text.status.unread
		return {
			bar: bar.bar,
			color,
			percent: bar.clamped,
		}
	})

	return (
		<box>
			<text fg={theme().text.default} attributes={TextAttributes.BOLD}>
				Context
			</text>
			<box flexDirection="row" gap={1}>
				<text fg={progress().color}>{progress().bar}</text>
				<text fg={progress().color}> {progress().percent}%</text>
			</box>
			<text fg={theme().text.subdued}>{detailLine()}</text>
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
