# quantize

This repository contains the files to build [`ollama/quantize`](https://hub.docker.com/r/ollama/quantize). It containerizes the scripts and utilities in [`llama.cpp`](https://github.com/ggerganov/llama.cpp) to create binary models to use with `llama.cpp` and compatible runners as [Ollama](https://github.com/jmorganca/ollama).

## Convert Pytorch model

```
docker run --rm -v /path/to/model/repo:/repo ollama/quantize -q q4_0 /repo
```

## Supported model families

### Llama2

- `LlamaForCausalLM`
- `MistralForCausalLM`
- `YiForCausalLM`

### Falcon

- `RWForCausalLM`
- `FalconForCausalLM`

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

Note: K-quants are not supported for Falcon models

## Learn more

https://github.com/jmorganca/ollama
