#!/bin/sh

for i in 3 4 5 6 7 8 9; do
  echo "Running with F2C=7 & C2F=$i..."
  k=0
  while [ $k -lt 10 ]; do
    echo "Attempt $k..."
    ./bench.sh $i 7 q
    ./bench.sh $i 7 r
    ./bench.sh $i 7 s
    k=$(($k + 1))
  done
done

for i in 8 9; do
  echo "Running with F2C=$i & C2F=7..."
  k=0
  while [ $k -lt 10 ]; do
    echo "Attempt $k..."
    ./bench.sh 7 $i s
    k=$(($k + 1))
  done
done
