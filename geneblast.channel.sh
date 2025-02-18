#!/bin/bash

# 检查参数是否提供
if [ $# -ne 1 ]; then
    echo "使用方法: $0 <Gene_ID>"
    exit 1
fi

# 读取输入基因 ID
GENE_ID=$1
FASTA_FILE="channel.pep.fa"
DB="blue_db"
TMP_FASTA="tmp2.fa"
BLAST_RESULT="blastp_result.c2b.txt"

# 1️⃣ 查找基因 ID 并提取完整 FASTA 头部
HEADER=$(grep "$GENE_ID" "$FASTA_FILE" | awk '{print $1}' | sed 's/>//')

if [ -z "$HEADER" ]; then
    echo "错误: 未找到基因 ID $GENE_ID"
    exit 1
fi

echo "找到匹配的 FASTA 头部: $HEADER"

# 2️⃣ 使用 seqkit 提取该基因的序列
seqkit grep -p "$HEADER" "$FASTA_FILE" > "$TMP_FASTA"

# 检查 tmp.fa 是否正确生成
if [ ! -s "$TMP_FASTA" ]; then
    echo "错误: 没有找到对应的序列"
    exit 1
fi

echo "已提取 $HEADER 序列到 $TMP_FASTA"

# 3️⃣ 运行 blastp 进行比对
blastp -query "$TMP_FASTA" -db "$DB" -out "$BLAST_RESULT" -evalue 1e-5 -outfmt 6 -num_threads 4 -max_target_seqs 5

# 检查 blastp 结果
if [ -s "$BLAST_RESULT" ]; then
    echo "比对完成，结果已保存到 $BLAST_RESULT"
else
    echo "警告: BLAST 比对未找到匹配结果"
fi

#awk 'BEGIN {max_pident=0} {if ($3 > max_pident) {max_pident=$3; best=$0}} END {print best}' blastp_result.c2b.txt
sort -k3,3nr blastp_result.c2b.txt | head -n 3
echo "#########################"
cat blastp_result.c2b.txt
#awk 'NR==1 {max_pident=$3} $3 == max_pident' blastp_result.c2b.txt

