#!/bin/sh

set -eu

usage() {
    echo >&2 "usage: $(basename $0) [-q QUANT] MODEL"
    echo >&2
    echo >&2 'Flags:'
    echo >&2 '  -q QUANT - Quantization type. One of:'
    echo >&2 '               - q4_0 (default)'
    echo >&2 '               - q4_1'
    echo >&2 '               - q5_0'
    echo >&2 '               - q5_1'
    echo >&2 '               - q8_0'
    echo >&2 '               - q2_K'
    echo >&2 '               - q3_K_S'
    echo >&2 '               - q3_K_M'
    echo >&2 '               - q3_K_L'
    echo >&2 '               - q4_K_S'
    echo >&2 '               - q4_K_M'
    echo >&2 '               - q5_K_S'
    echo >&2 '               - q5_K_M'
    echo >&2 '               - q6_K'
    exit 1
}

QUANT='q4_0'
while getopts "hq:" OPTION; do
    case $OPTION in
        q) QUANT=$OPTARG ;;
    esac
done

shift $(( $OPTIND - 1 ))
[ $# -eq 1 ] || usage
MODEL=$(realpath $1)

if [ ! -f "$MODEL/f16.bin" ]; then
    # convert to f16 GGUF
    ARCHITECTURE="$(jq -r '.architectures[0]' $MODEL/config.json)"

    CONVERT=
    CONVERT_ARGS=
    case "$ARCHITECTURE" in
        LlamaForCausalLM|MistralForCausalLM|YiForCausalLM) CONVERT='convert.py'; CONVERT_ARGS='--outtype f16' ;;
        RWForCausalLM|FalconForCausalLM) CONVERT='convert-falcon-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
        GPTNeoXForCausalLM) CONVERT='convert-gptneox-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
        GPTBigCodeForCausalLM) CONVERT='convert-starcoder-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
        MPTForCausalLM) CONVERT='convert-mpt-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
        BaichuanForCausalLM) CONVERT='convert-baichuan-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
        PersimmonForCausalLM) CONVERT='convert-persimmon-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
        RefactForCausalLM) CONVERT='convert-refact-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
        BloomForCausalLM) CONVERT='convert-bloom-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
        *) echo >&2 "unknown architecture $ARCHITECTURE"; exit ;;
    esac

    python "llama.cpp/$CONVERT" --outfile "$MODEL/f16.bin" "$MODEL" $CONVERT_ARGS
fi

case $QUANT in
    q4_0|q4_1|q5_0|q5_1|q8_0|q2_K|q3_K_S|q3_K_M|q3_K_L|q4_K_S|q4_K_M|q5_K_S|q5_K_M|q6_K) ;;
    f16) exit 0 ;;
    *) usage ;;
esac

if [ ! -f "$MODEL/$QUANT.bin" ]; then
    # quantize to descired type
    ./llama.cpp/build/bin/quantize "$MODEL/f16.bin" "$MODEL/$QUANT.bin" "$QUANT"
fi
