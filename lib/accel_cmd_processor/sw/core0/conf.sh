source ../../../../global_conf.sh

export MIPS32_NUM_TEXT_MEM_BLOCKS=1
export MIPS32_NUM_DATA_MEM_BLOCKS=1

export MIPS32_TEXT_SIZE=$(expr 4096 \* $MIPS32_NUM_TEXT_MEM_BLOCKS)
export MIPS32_DATA_SIZE=$(expr 4096 \* $MIPS32_NUM_DATA_MEM_BLOCKS)

export MIPS32_STACK_SIZE=128
export MIPS32_HEAP_SIZE=64

export NUM_NYUZI_THREADS=32

