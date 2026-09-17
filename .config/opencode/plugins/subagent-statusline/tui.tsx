/**
 * Subagent status section for the OpenCode V2 session sidebar.
 *
 * Port of the sidebar feature of Joaquinvesapa/sub-agent-statusline (V1 API)
 * to the V2 plugin API. Renders in sidebar.content:
 *
 *   ▼ Subagents
 *   ● 1 run · ✓ 2 done · ✕ 0 err · Σ 3
 *     [ ] Explore the codebase
 *       ↳ ⏱ 00:34  12.3k
 *     [✓] Fix the failing test
 *       ↳ ⏱ 01:23
 *
 * Differences from the original by design: V2 SessionInfo carries the
 * child-session data the original reconstructed from raw events (state
 * file, hydration, running-reconcile maintenance), so all of that
 * machinery drops out. Row visuals, markers, colors, and duration format
 * match the original (statusColor: done→success, error→error, running→
 * warning; clock U+F017, token U+F51E; rows capped at 5, running first).
 */
/** @jsxImportSource @opentui/solid */
import { createMemo, createSignal, For, Show, onCleanup } from "solid-js"
import { Plugin, type Plugin as PluginTypes } from "@opencode/plugin/tui"

const CLOCK_ICON = "\uf017"
const TOKEN_ICON = "\uf51e"
const ARROW_EXPANDED = "▼"
const ARROW_COLLAPSED = "▶"
const MAX_ROWS = 5
const VERSION = "1.3.0"

type Child = {
	id: string
	title: string
	running: boolean
	failed: boolean
	tokens: number
	elapsedMs: number
}

function formatDuration(elapsedMs: number): string {
	const totalSeconds = Math.max(0, Math.floor(elapsedMs / 1000))
	const hours = Math.floor(totalSeconds / 3600)
	const minutes = Math.floor((totalSeconds % 3600) / 60)
	const seconds = totalSeconds % 60
	if (hours > 0)
		return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
	return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
}

function formatTokens(value: number): string {
	if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`
	if (value >= 1_000) return `${(value / 1_000).toFixed(1)}k`
	return String(Math.max(0, Math.round(value)))
}

function marker(status: "running" | "done" | "error"): string {
	if (status === "done") return "[✓]"
	if (status === "error") return "[x]"
	return "[ ]"
}

function View(props: { context: PluginTypes.Context; sessionID: string }) {
	const theme = () => props.context.theme
	const feedback = () => theme().text.feedback
	const [now, setNow] = createSignal(Date.now())
	const timer = setInterval(() => setNow(Date.now()), 1000)
	onCleanup(() => clearInterval(timer))
	const [store, setStore] = props.context.storage.store("subagents", {
		initial: { expanded: true },
	})

	const children = createMemo<Child[]>(() => {
		const all = props.context.data.session.list() ?? []
		const nowMs = now()
		return all
			.filter((s) => s.parentID === props.sessionID)
			.map((s) => {
				const running = props.context.data.session.status(s.id) === "running"
				const failed = s.outcome === "failed" || s.outcome === "interrupted"
				const done = s.outcome === "succeeded"
				const tokens =
					s.tokens.input + s.tokens.output + s.tokens.reasoning + s.tokens.cache.read + s.tokens.cache.write
				const created = s.time?.created ?? 0
				// time.updated echoes creation (ms later); time.idle is when the
				// session actually went quiet, so use it as the end timestamp.
				const end = running ? nowMs : s.time?.idle ?? s.time?.updated ?? nowMs
				return {
					id: s.id,
					title: s.title || s.agent || "subagent",
					running,
					failed,
					status: (running ? "running" : failed ? "error" : "done") as Child["status"],
					tokens,
					elapsedMs: created ? Math.max(0, end - created) : 0,
					created,
				}
			})
			.sort((a, b) => {
				if (a.running !== b.running) return a.running ? -1 : 1
				return b.created - a.created
			})
	})

	const counts = createMemo(() => {
		const list = children()
		return {
			running: list.filter((c) => c.running).length,
			done: list.filter((c) => c.status === "done").length,
			error: list.filter((c) => c.status === "error").length,
			total: list.length,
		}
	})

	const visible = createMemo(() => children().slice(0, MAX_ROWS))

	const open = (sessionID: string) => {
		void props.context.ui.router.navigate({ type: "session", sessionID })
	}

	return (
		<Show when={children().length > 0}>
			<box flexDirection="column">
				<box flexDirection="row">
					<text
						fg={theme().text.default}
						onMouseDown={() => void setStore((draft) => void (draft.expanded = !draft.expanded))}
					>{`${store.expanded ? ARROW_EXPANDED : ARROW_COLLAPSED} Subagents`}</text>
					<text fg={theme().text.subdued}>{` ${VERSION}`}</text>
				</box>
				<box flexDirection="row">
					<text fg={feedback().warning.default}>{`● ${counts().running} run`}</text>
					<text fg={theme().text.subdued}> · </text>
					<text fg={feedback().success.default}>{`✓ ${counts().done} done`}</text>
					<text fg={theme().text.subdued}> · </text>
					<text fg={feedback().error.default}>{`✕ ${counts().error} err`}</text>
					<text fg={theme().text.subdued}> · </text>
					<text fg={theme().text.default}>{`Σ ${counts().total}`}</text>
				</box>
				<Show when={store.expanded}>
					<box flexDirection="column">
						<For each={visible()}>{(child) => <Row child={child} context={props.context} />}</For>
					</box>
				</Show>
			</box>
		</Show>
	)

	function Row(props: { child: Child; context: PluginTypes.Context }) {
		const theme = () => props.context.theme
		const statusColor = () => {
			const f = theme().text.feedback
			if (props.child.status === "done") return f.success.default
			if (props.child.status === "error") return f.error.default
			return f.warning.default
		}
		const elapsed = () => formatDuration(props.child.elapsedMs)
		return (
			<box
				flexDirection="column"
				onMouseUp={() => void props.context.ui.router.navigate({ type: "session", sessionID: props.child.id })}
			>
				<box flexDirection="row">
					<text fg={theme().text.subdued}>{" "}</text>
					<text fg={statusColor()}>{marker(props.child.status)}</text>
					<text fg={theme().text.default}>{` ${props.child.title}`}</text>
				</box>
				<box flexDirection="row" paddingLeft={4}>
					<text fg={theme().text.subdued}>{`↳ ${CLOCK_ICON} ${formatDuration(props.child.elapsedMs)}`}</text>
					<Show when={props.child.tokens > 0}>
						<text fg={theme().text.subdued}>{` ${TOKEN_ICON} ${formatTokens(props.child.tokens)}`}</text>
					</Show>
				</box>
			</box>
		)
	}
}

export default Plugin.define({
	id: "local.subagent-statusline",
	setup(context) {
		context.ui.slot({
			append: "sidebar.content",
			render: (props) => <View context={context} sessionID={props.sessionID} />,
		})
	},
})
