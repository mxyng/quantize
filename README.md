# quantize

This repository contains the files to build [`ollama/quantize`](https://hub.docker.com/r/ollama/quantize). It containerizes the scripts and utilities in [`llama.cpp`](https://github.com/ggerganov/llama.cpp) to create binary models to use with `llama.cpp` and compatible runners as [Ollama](https://github.com/jmorganca/ollama).

## Convert Pytorch model

```
docker run --rm -v /path/to/model/repo:/repo ollama/quantize -q q4_0 /repo
```

This will produce two binaries in the repo: `f16.bin`, the unquantized model weights in GGUF format, and `q4_0.bin`, the same weights after 4-bit quantization.

## Supported model families

### Llama2

- `LlamaForCausalLM`
- `MistralForCausalLM`
- `YiForCausalLM`
- `LlavaLlamaForCausalLM`
- `LlavaMistralForCausalLM`

> Note: Llava models will produce other intermediary files: `llava.projector`, the vision tensors split from the Pytorch model, and `mmproj-model-f16.gguf`, the same tensors converted to GGUF. The final model will contain both the base model as well as the projector. Use `-m no` to disable this behaviour.

### Falcon

- `RWForCausalLM`
- `FalconForCausalLM`

### GPTNeoX

- `GPTNeoXForCausalLM`

### StarCoder

- `GPTBigCodeForCausalLM`

### MPT

- `MPTForCausalLM`

### Baichuan

- `BaichuanForCausalLM`

### Persimmon

- `PersimmonForCausalLM`

### Refact

- `RefactForCausalLM`

### Bloom

- `BloomForCausalLM`

### StableLM

- `StableLMEpochForCausalLM`
- `LlavaStableLMEpochForCausalLM`

### Mixtral

- `MixtralForCausalLM`

## Supported quantizations

- `q4_0` (default), `q4_1`
- `q5_0`, `q5_1`
- `q8_0`

### K-quants

- `q2_K`
- `q3_K_S`, `q3_K_M`, `q3_K_L`
- `q4_K_S`, `q4_K_M`
- `q5_K_S`, `q5_K_M`
- `q6_K`

> Note: K-quants are not supported for Falcon models

## Learn more

https://github.com/jmorganca/ollama
