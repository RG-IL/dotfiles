interface NotifyBackendOptions {
	preferCmux: boolean
	tryCmuxNotify: () => Promise<boolean>
	sendDesktopNotification: () => void | Promise<void>
}

export interface DesktopNotificationOptions {
	title: string
	message: string
	subtitle?: string
	sound?: string
	senderBundleId?: string | null
	tmuxPaneId?: string
	tmuxWindowId?: string
}

interface DesktopNotificationRouterOptions extends DesktopNotificationOptions {
	platform: NodeJS.Platform | string
	sendNodeNotifierNotification: () => void
	sendMacOSNotification?: (options: DesktopNotificationOptions) => Promise<boolean>
}

interface AlerterProcess {
	exited: Promise<number>
}

interface AlerterRuntime {
	which?: (command: string) => string | null | Promise<string | null>
	spawnProcess?: (argv: string[]) => AlerterProcess
	warn?: (message: string) => void
}

const ALERTER_INSTALL_HINT =
	"install vjeantet/alerter (brew install vjeantet/tap/alerter) and ensure it is on PATH"

const OPENCODE_ICON_PATH = `${require("node:os").homedir()}/.config/opencode/opencode-icon.png`

export function buildAlerterArguments(options: DesktopNotificationOptions): string[] {
	const argv = ["alerter", "--message", options.message, "--title", options.title, "--app-icon", OPENCODE_ICON_PATH, "--timeout", "5"]

	if (options.subtitle) {
		argv.push("--subtitle", options.subtitle)
	}

	if (options.sound) {
		argv.push("--sound", options.sound)
	}

	if (options.senderBundleId) {
		argv.push("--sender", options.senderBundleId)
	}

	return argv
}

function getBunWhich(): ((command: string) => string | null | Promise<string | null>) | undefined {
	try {
		return Bun.which
	} catch {
		return undefined
	}
}

function getBunSpawn():
	| ((argv: string[], opts?: Record<string, unknown>) => { exited: Promise<number>; kill?: () => void; stdout?: ReadableStream })
	| undefined {
	try {
		return (argv: string[]) => {
			const proc = Bun.spawn(argv, { stdout: "pipe", stderr: "pipe" })
			return { exited: proc.exited, kill: () => proc.kill(), stdout: proc.stdout }
		}
	} catch {
		return undefined
	}
}

async function activateGhostty(tmuxPaneId?: string, tmuxWindowId?: string): Promise<void> {
	try {
		if (typeof Bun !== "undefined") {
			Bun.spawn(["osascript", "-e", 'tell application "Ghostty" to activate'], {
				stdout: "ignore",
				stderr: "ignore",
			})
		} else {
			const { spawn } = require("node:child_process") as typeof import("node:child_process")
			spawn("osascript", ["-e", 'tell application "Ghostty" to activate'], { stdio: "ignore" })
		}
	} catch {
		// Best effort
	}

	setTimeout(() => {
		try {
			const argv: string[] = ["tmux"]
			// Switch to the OpenCode window first (handles cross-window navigation)
			if (tmuxWindowId) {
				argv.push("select-window", "-t", tmuxWindowId)
			}
			// Then select the specific pane within that window
			if (tmuxPaneId) {
				if (tmuxWindowId) argv.push(";")
				argv.push("select-pane", "-t", tmuxPaneId)
			}
			if (argv.length > 1) {
				if (typeof Bun !== "undefined") {
					Bun.spawn(argv, { stdout: "ignore", stderr: "ignore" })
				} else {
					const { spawn } = require("node:child_process") as typeof import("node:child_process")
					spawn(argv[0]!, argv.slice(1), { stdio: "ignore" })
				}
			}
		} catch {
			// Best effort
		}
	}, 200)
}

export async function sendMacOSAlerterNotification(
	options: DesktopNotificationOptions,
	runtime: AlerterRuntime = {},
): Promise<boolean> {
	const bunWhich = getBunWhich()
	const which = runtime.which ?? bunWhich
	const warn = runtime.warn ?? console.warn

	try {
		const alerterPath = await (typeof which === "function" ? which("alerter") : whichAlerterNode())
		if (!alerterPath) {
			warn(`notify: macOS desktop notification skipped; alerter not found on PATH (${ALERTER_INSTALL_HINT}).`)
			return false
		}

		const alerterArguments = buildAlerterArguments(options)
		const bunSpawn = getBunSpawn()
		const spawnProcess =
			runtime.spawnProcess ??
			bunSpawn ??
			((argv: string[]) => {
				const { spawn } = require("node:child_process") as typeof import("node:child_process")
				const proc = spawn(argv[0]!, argv.slice(1), { stdio: ["ignore", "pipe", "pipe"] })
				return {
					exited: new Promise<number>((resolve) => {
						proc.on("close", resolve)
						proc.on("error", () => resolve(1))
					}),
					stdout: proc.stdout,
				}
			})
		const process = spawnProcess([alerterPath, ...alerterArguments.slice(1)])
		const exitCode = await process.exited

		if (exitCode !== 0) {
			warn(`notify: macOS desktop notification skipped; alerter exited with code ${exitCode}.`)
			return false
		}

		// Check if user clicked the notification
		try {
			const output =
				"stdout" in process
					? await new Response((process as { stdout: NodeJS.ReadableStream }).stdout as ReadableStream).text()
					: ""
			if (output.includes("@CONTENTCLICKED")) {
				activateGhostty(options.tmuxPaneId, options.tmuxWindowId)
			}
		} catch {
			// Best effort
		}

		return true
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error)
		warn(`notify: macOS desktop notification skipped; alerter failed (${message}).`)
		return false
	}
}

async function whichAlerterNode(): Promise<string | null> {
	try {
		const { execFile } = await import("node:child_process")
		return await new Promise<string | null>((resolve) => {
			const proc = execFile("which", ["alerter"], (error, stdout) => {
				if (error) resolve(null)
				else resolve(stdout.trim() || null)
			})
			proc.on("error", () => resolve(null))
		})
	} catch {
		return null
	}
}

export async function sendDesktopNotificationByPlatform(
	options: DesktopNotificationRouterOptions,
): Promise<void> {
	const { platform, sendNodeNotifierNotification, sendMacOSNotification, ...notificationOptions } = options

	if (platform === "darwin") {
		await (sendMacOSNotification ?? sendMacOSAlerterNotification)(notificationOptions)
		return
	}

	sendNodeNotifierNotification()
}

export async function sendNotificationWithFallback(options: NotifyBackendOptions): Promise<void> {
	if (!options.preferCmux) {
		await options.sendDesktopNotification()
		return
	}

	try {
		const sentViaCmux = await options.tryCmuxNotify()
		if (sentViaCmux) return
	} catch {
		// Fall through to desktop notification fallback
	}

	await options.sendDesktopNotification()
}
