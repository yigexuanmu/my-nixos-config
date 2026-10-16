#!/usr/bin/env bash

# 配置
CHARS="▁▂▃▄▅▆▇█"
BARS=12
FPS=60
SENS=150
CONF="/tmp/waybar_cava_config"

# 初始化
len=$((${#CHARS}-1))
idle_char="${CHARS:0:1}"
idle_output=$(printf "%0.s$idle_char" $(seq 1 $BARS))

# 生成 Cava 配置
cat > "$CONF" <<EOF
[general]
framerate = $FPS
sensitivity = $SENS
bars = $BARS
lower_cutoff_freq = 20
higher_cutoff_freq = 20000
[input]
method = ${CAVA_METHOD:-pipewire}
source = auto
sample_rate = 192000
sample_bits = 16
channels = 2
active = 1
remix = 1
virtual = 0
[smoothing]
integral = 0
monstercat = 0
waves = 0
gravity = 0
ignore = 0
noise_reduction = 0
[eq]
1 = 1
2 = 1
3 = 1
4 = 1
5 = 1
[output]
channels = mono
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = $len
EOF

cleanup() {
    trap - EXIT INT TERM
    pkill -P $$ 2>/dev/null
    echo "$idle_output"
    exit 0
}
trap cleanup EXIT INT TERM

# 核心检测：是否有客户端的音频输出流
is_audio_active() {
    if [ "${CAVA_STRICT:-0}" = 1 ] && command -v jq >/dev/null 2>&1; then
        pw-dump 2>/dev/null | jq -e 'any(.[]; .info.props."media.class"? == "Stream/Output/Audio" and .info.state == "running")' >/dev/null 2>&1
    else
        pw-cli ls Node 2>/dev/null | grep -q 'media.class = "Stream/Output/Audio"'
    fi
}

# 初始状态
echo "$idle_output"

while true; do
    # 如果存在未静音的音频
    if is_audio_active; then
        if ! pgrep -P $$ -x cava >/dev/null; then
            # 这里的 sed 字典是根据你的 CHARS 动态生成的
            sed_dict="s/^(([^;]*;){$BARS}).*/\1/;s/;//g;"
            for ((i=0; i<=${len}; i++)); do
                sed_dict="${sed_dict}s/$i/${CHARS:$i:1}/g;"
            done
            cava -p "$CONF" 2>/dev/null | sed -uE "$sed_dict" &
        fi
        # 正在播放时，稍微降低检查频率减少 CPU 占用
        sleep 1
    else
        if pgrep -P $$ -x cava >/dev/null; then
            pkill -P $$ -x cava 2>/dev/null
            wait 2>/dev/null
            echo "$idle_output"
        fi
        sleep "${CAVA_IDLE_INTERVAL:-2}"
    fi
done
