#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Synopsis: $0 <run-id>"
    echo "  e.g $0 cv-4-7"
    exit 1
fi
GROUP=$1
FAMILY=$(echo $GROUP | perl -ane 'if(m/^(.*?)-/g){print $1;}')
if [ ${FAMILY} = "cv" ]; then
  FAMILY="Cyclone V"
  XRANGE="1300:2000"
elif [ ${FAMILY} = "sv" ]; then
  FAMILY="Stratix V"
  XRANGE="1700:2400"
fi
REQSIZE=$(echo $GROUP | perl -ane 'if(m/^.*?-.*?-(.*?)$/g){print 2**$1;}')
RSPSIZE=$(echo $GROUP | perl -ane 'if(m/^.*?-(.*?)-/g){print 2**$1;}')
cat ../${GROUP}-s.txt | perl -ane 'if(m/(\d+): (\d+)$/g){printf("%0.3f %0.4f\n", $1*8, $2/100000.0);}' > s.txt
cat ../${GROUP}-q.txt | perl -ane 'if(m/(\d+): (\d+)$/g){printf("%0.3f %0.4f\n", $1*8, $2/100000.0);}' > q.txt
cat ../${GROUP}-r.txt | perl -ane 'if(m/(\d+): (\d+)$/g){printf("%0.3f %0.4f\n", $1*8, $2/100000.0);}' > r.txt
#set xtics 0, 25 rotate by -60 font ",12"
gnuplot <<EOF
set term svg enhanced size 1440, 1440 background rgb 'white'
set title "$FAMILY: Request:$REQSIZE, Response:$RSPSIZE" font ",20"
set xrange [$XRANGE]
set yrange [0:40]
set xtics 0, 50
set ytics 0, 1
set format y ""
set xlabel "latency (ns)" font ",20"
set ylabel "likelihood" font ",20"
set output "${GROUP}.svg"
plot \
  'q.txt' using 1:2 title 'queue' smooth csplines lw 3 lc rgb 'blue', \
  'r.txt' using 1:2 title 'regs' smooth csplines lw 3 lc rgb 'black', \
  's.txt' using 1:2 title 'single-reg' smooth csplines lw 3 lc rgb 'red'
EOF
rm -f s.txt q.txt r.txt
