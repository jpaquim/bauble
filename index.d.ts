/// <reference types="emscripten" />

export interface EvaluationResult {
  isError: boolean;
  shaderSource: string;
  isAnimated: boolean;
  error: string;
}

export interface BaubleModule extends EmscriptenModule {
  evaluate_script: (_: string) => EvaluationResult;
  // TODO
  FS: any;
}

declare const baubleFactory: EmscriptenModuleFactory<BaubleModule>;
export default baubleFactory;
