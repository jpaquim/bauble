/// <reference types="emscripten" />

export interface EvaluationResult {
	isError: boolean;
	shaderSource: string;
	isAnimated: boolean;
	error: string;
}

export interface BaubleModule extends EmscriptenModule {
	evaluate_script: (_: string) => EvaluationResult;
	// TODO, obviosly
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	FS: any;
}

declare const baubleFactory: EmscriptenModuleFactory<BaubleModule>;
export default baubleFactory;
