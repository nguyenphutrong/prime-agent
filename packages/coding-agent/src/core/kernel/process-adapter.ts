export interface KernelProcessRequest {
	readonly command: string;
	readonly args: readonly string[];
	readonly cwd?: string;
	readonly env: NodeJS.ProcessEnv;
}

export interface KernelProcessPlan {
	readonly command: string;
	readonly args: readonly string[];
	readonly cwd?: string;
	readonly env: NodeJS.ProcessEnv;
	/** Synchronous cleanup for launch artifacts such as generated sandbox settings. */
	readonly cleanup?: () => void;
}

/**
 * Alters how an IPython kernel process is launched. When present, the kernel
 * fork server is bypassed so every kernel crosses this seam.
 */
export interface KernelProcessAdapter {
	prepare(request: KernelProcessRequest): KernelProcessPlan | Promise<KernelProcessPlan>;
}
