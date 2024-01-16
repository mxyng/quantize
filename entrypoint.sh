#!/bin/sh

set -eu

usage() {
    echo >&2 "usage: $(basename $0) [-m yes|no] [-n] [-q QUANT] MODEL"
    echo >&2
    echo >&2 'Converts a Pytorch model to GGUF format.'
    echo >&2
    echo >&2 'Flags:'
    echo >&2 '  -m yes|no - Merge the base model with the projector. Default: yes.'
    echo >&2 '  -n        - Dry run. Do not actually run any commands.'
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
    echo >&2 '               - f16'
    exit 1
}

MERGE=yes
DRYRUN=
QUANT='q4_0'
while getopts "hm:nq:" OPTION; do
    case $OPTION in
        m) MERGE=$OPTARG ;;
        n) DRYRUN=echo ;;
        q) QUANT=$OPTARG ;;
        *) usage ;;
    esac
done

case $MERGE in
    yes|no) ;;
    *) usage ;;
esac

case $QUANT in
    q4_0|q4_1|q5_0|q5_1|q8_0|q2_K|q3_K_S|q3_K_M|q3_K_L|q4_K_S|q4_K_M|q5_K_S|q5_K_M|q6_K|f16) ;;
    *) usage ;;
esac

shift $(( $OPTIND - 1 ))
[ $# -eq 1 ] || usage
MODEL="$(realpath $1)"

# convert to f16 GGUF
ARCHITECTURE="$(jq -r '.architectures[0]' $MODEL/config.json)"

CONVERT=
CONVERT_ARGS=
case "${ARCHITECTURE%ForCausalLM}" in
    Llama|Mistral|Yi|LlavaLlama|LlavaMistral) CONVERT='convert.py'; CONVERT_ARGS='--outtype f16' ;;
    RW|Falcon|GPTNeoX|GPTBigCode|MPT|GPTRefact|Bloom|Baichuan|StableLMEpoch|LlavaStableLMEpoch|Mixtral) CONVERT='convert-hf-to-gguf.py'; CONVERT_ARGS='--outtype f16' ;;
    Persimmon) CONVERT='convert-persimmon-hf-to-gguf.py'; CONVERT_ARGS='1' ;;
    *) echo >&2 "unknown architecture $ARCHITECTURE"; exit ;;
esac

echo "$ARCHITECTURE" | grep -q '^Llava' && LLAVA=1 || LLAVA=0
if [ "$LLAVA" -eq 1 ]; then
    if [ ! -f "$MODEL/llava.projector" ]; then
        # do some surgery
        $DRYRUN python llama.cpp/examples/llava/llava-surgery.py -m "$MODEL"
    fi

    if [ ! -f "$MODEL/mmproj-model-f16.gguf" ]; then
        if [ ! -d "$MODEL/openai" ]; then
            git clone https://huggingface.co/openai/clip-vit-large-patch14-336 "$MODEL/openai"
        fi

        $DRYRUN python llama.cpp/examples/llava/convert-image-encoder-to-gguf.py -m "$MODEL/openai" --llava-projector "$MODEL/llava.projector" --output-dir "$MODEL"
    fi
fi

if [ ! -f "$MODEL/f16.bin" ] || [ "$LLAVA" -eq 1 ]; then
    $DRYRUN python "llama.cpp/$CONVERT" --outfile "$MODEL/f16.bin" "$MODEL" $CONVERT_ARGS
fi

if [ ! -f "$MODEL/$QUANT.bin" ] || [ "$LLAVA" -eq 1 ]; then
    # quantize to desired type
    $DRYRUN ./llama.cpp/build/bin/quantize "$MODEL/f16.bin" "$MODEL/$QUANT.bin" "$QUANT"
fi

if [ "$LLAVA" -eq 1 ] && [ "$MERGE" = "yes" ]; then
    # merge base model with projector
    cat "$MODEL/mmproj-model-f16.gguf" >>"$MODEL/$QUANT.bin"
fi
