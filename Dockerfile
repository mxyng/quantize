FROM --platform=$TARGETPLATFORM python:3.10-slim
WORKDIR /workdir
ARG BRANCH=master

RUN apt-get update \
    && apt-get install -y git build-essential cmake jq \
    && pip install torch --index-url https://download.pytorch.org/whl/cpu \
    && pip install transformers sentencepiece

RUN git clone --branch $BRANCH --single-branch https://github.com/ggerganov/llama.cpp.git llama.cpp \
    && cmake -S llama.cpp -B llama.cpp/build \
    && cmake --build llama.cpp/build --target quantize

COPY entrypoint.sh .
ENTRYPOINT ["sh", "entrypoint.sh"]