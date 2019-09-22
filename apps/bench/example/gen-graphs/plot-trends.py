#!/usr/bin/env python3
import math
import re
import os
import sys
import glob
import subprocess

#if (len(sys.argv) != 2):
#    print("Synopsis: {} <run-id>".format(sys.argv[0]))
#    sys.exit(1)

def calcMeanAndSD(fileName):
    latencies = []
    frequencies = []
    with open(fileName, "r") as f:
        for line in f.readlines():
            m = re.search(r"^(\d+):\s(\d+)$", line)
            if (m != None):
                latencies.append(8 * int(m.group(1)))
                frequencies.append(int(m.group(2)))

    N = 0
    for f in frequencies:
        N += f

    mean = 0.0
    for i in range(0, len(latencies)):
        mean += latencies[i] * frequencies[i]
    mean /= N

    variance = 0.0
    for i in range(0, len(latencies)):
        distanceFromMean = latencies[i] - mean
        variance += frequencies[i] * distanceFromMean * distanceFromMean
    variance /= N
    return (mean, math.sqrt(variance))

def genSpec(title, svgName, xRange, yRange, xTics, reqRes, plotMap):
    template = '''set term svg enhanced size 1440, 1440 background rgb "white"
set title "{}" font ",20"
set xrange [{}]
set yrange [{}]
set xtics {}
set ytics 0, 100
set xlabel "{} size (bytes)" font ",20"
set ylabel "latency (ns)" font ",20"
set output "{}"
plot '''
    template += ", ".join(['"{}" using 1:2:3 title "" with errorbars, "" title "{}" smooth csplines lw 3 lc rgb "{}"'.format(i, plotMap[i][0], plotMap[i][1]) for i in plotMap.keys()])
    template += "\n"
    return template.format(title, xRange, yRange, xTics, reqRes, svgName).encode()

def genGraph(pattern, rex, title, svgName, xRange, yRange, xTics, reqRes, plotMap):
    # Make an empty list for each key in plotMap, representing each file to plot (e.g q.txt, r.txt,
    # s.txt)
    outFiles = dict()
    for key in plotMap.keys():
        outFiles[key] = []

    # Calculate mean and standard deviation for each file in the glob pattern, and add a row to the
    # appropriate plot file
    files = glob.glob(pattern)
    for thisFile in files:
        print("Processing: {}".format(thisFile))
        m = re.search(rex, thisFile)
        if (m != None):
            msgSize = 2**int(m.group(1))
            ident = m.group(2)
            (mean, sd) = calcMeanAndSD(thisFile)
            outFiles[ident].append([msgSize, mean, sd])

    # Write each file, sorted by the msgSize
    for key, outFile in outFiles.items():
        with open(key, "w") as f:
            for row in sorted(outFile, key=lambda x:x[0], reverse=False):
                f.write("{0} {1:.2f} {2:.2f}\n".format(row[0], row[1], row[2]))

    # Run gnuplot
    spec = genSpec(title, svgName, xRange, yRange, xTics, reqRes, plotMap)
    proc = subprocess.Popen(["gnuplot"], stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(proc.communicate(input = spec)[0])

    # Clean up plot files
    for key in plotMap.keys():
        os.remove(key)

genGraph(
    "../cv-*-7-*.txt",
    r"^../cv-(\d+)-7-([qrs].txt)$",
    "Cyclone V: PCIe Round-Trip Latency Overview (Request: 128)",
    "cv-response-trends-overview.svg",
    "0:520", "0:6000", "0, 25", "response",
    {"q.txt":("queue", "blue"), "r.txt":("regs", "black"), "s.txt":("single-reg", "red")}
)
genGraph(
    "../sv-*-7-*.txt",
    r"^../sv-(\d+)-7-([qrs].txt)$",
    "Stratix V: PCIe Round-Trip Latency Overview (Request: 128)",
    "sv-response-trends-overview.svg",
    "0:520", "0:6000", "0, 25", "response",
    {"q.txt":("queue", "blue"), "r.txt":("regs", "black"), "s.txt":("single-reg", "red")}
)
genGraph(
    "../cv-*-7-*.txt",
    r"^../cv-(\d+)-7-([qrs].txt)$",
    "Cyclone V: PCIe Round-Trip Latency Detail (Request: 128)",
    "cv-response-trends-detail.svg",
    "0:72", "1300:2400", "0, 8", "response",
    {"q.txt":("queue", "blue"), "r.txt":("regs", "black"), "s.txt":("single-reg", "red")}
)
genGraph(
    "../sv-*-7-*.txt",
    r"^../sv-(\d+)-7-([qrs].txt)$",
    "Stratix V: PCIe Round-Trip Latency Detail (Request: 128)",
    "sv-response-trends-detail.svg",
    "0:72", "1300:2400", "0, 8", "response",
    {"q.txt":("queue", "blue"), "r.txt":("regs", "black"), "s.txt":("single-reg", "red")}
)
genGraph(
    "../cv-7-*-s.txt",
    r"^../cv-7-(\d+)-(s.txt)$",
    "Cyclone V: PCIe Round-Trip Latency (Response: SingleDW)",
    "cv-request-trends.svg",
    "120:520", "0:2700", "0, 25", "request",
    {"s.txt":("", "blue")}
)
genGraph(
    "../sv-7-*-s.txt",
    r"^../sv-7-(\d+)-(s.txt)$",
    "Stratix V: PCIe Round-Trip Latency (Response: SingleDW)",
    "sv-request-trends.svg",
    "120:520", "0:2700", "0, 25", "request",
    {"s.txt":("", "blue")}
)
#genGraph("../sv-*-7-*.txt", b"Stratix V", b"1300:6000", b"sv-response-trends.svg")
#genGraph("../sv-*-7-*.txt", b"Stratix V", b"1300:6000", b"sv-response-trends.svg")
#
