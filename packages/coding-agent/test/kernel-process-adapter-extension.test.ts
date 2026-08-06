import { describe, expect, it } from "vitest";
import { createEventBus } from "../src/core/event-bus.js";
import { createExtensionRuntime, loadExtensionFromFactory } from "../src/core/extensions/loader.js";

describe("kernel process adapter extension registration", () => {
	it("stores one adapter during extension loading", async () => {
		const runtime = createExtensionRuntime();
		const adapter = {
			prepare: (request: Parameters<NonNullable<typeof runtime.kernelProcessAdapter>["prepare"]>[0]) => request,
		};
		await loadExtensionFromFactory(
			(pi) => pi.registerKernelProcessAdapter(adapter),
			process.cwd(),
			createEventBus(),
			runtime,
		);
		expect(runtime.kernelProcessAdapter).toBe(adapter);
	});

	it("rejects multiple adapters", async () => {
		const runtime = createExtensionRuntime();
		const adapter = {
			prepare: (request: Parameters<NonNullable<typeof runtime.kernelProcessAdapter>["prepare"]>[0]) => request,
		};
		await loadExtensionFromFactory(
			(pi) => pi.registerKernelProcessAdapter(adapter),
			process.cwd(),
			createEventBus(),
			runtime,
		);
		await expect(
			loadExtensionFromFactory(
				(pi) => pi.registerKernelProcessAdapter(adapter),
				process.cwd(),
				createEventBus(),
				runtime,
			),
		).rejects.toThrow("Only one IPython kernel process adapter can be registered");
	});
});
