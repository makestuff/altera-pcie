#!/usr/bin/env python3

# cd $PROJ_HOME
# cat $(find . -name "transcript" | sort) > transcripts.txt
# TRANSCRIPT=transcripts.txt tools/ersatz-gtest.py --gtest_output=xml:/w/public_html/svunit.xml

from __future__ import print_function
import re, argparse, sys, os
from enum import Enum

HEADER = '''<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="gtest2html.xslt"?>
<testsuites tests="{}" failures="{}" disabled="0" errors="0" timestamp="2019" time="0" name="AllTests">
  <testsuite name="{}" tests="{}" failures="{}" disabled="0" errors="0" time="0">
'''

NEWSUITE = '''  </testsuite>
  <testsuite name="{}" tests="{}" failures="{}" disabled="0" errors="0" time="0">
'''

class State(Enum):
  AWAIT_SUITE = 1
  AWAIT_TEST_BEGIN = 2
  AWAIT_TEST_END = 3

if __name__ == "__main__":
  globalTestCount = 0
  globalFailCount = 0
  state = State.AWAIT_SUITE

  parser = argparse.ArgumentParser(description='Build and test HDL code.')
  parser.add_argument('--gtest_output=xml:', '-b', action="store", nargs=1, metavar="<output-xml>", help="the file destination for the XML report")
  argList = vars(parser.parse_args())
  outFile = argList['gtest_output=xml:'][0][4:]
  transcript = os.environ['TRANSCRIPT']

  if (os.name == "nt"):
    winDrive = re.search(r"^/([a-z])(/.*?)$", outFile)
    if (winDrive != None):
      outFile = winDrive.group(1) + ":" + winDrive.group(2)
  if (outFile.startswith("~/")):
    outFile = os.environ['HOME'] + outFile[1:]
  
  with open(outFile, "w") as outFile:
    testCounts = {}
    failCounts = {}
    
    # Find out how many tests there are, and how many failures
    with open(transcript) as inFile:
      for line in inFile:
        summary = re.search(r"^# INFO:\s+\[\d+\]\[(.*?)\]: [PF]A[SI][SL]ED \((\d+) of (\d+) tests passing\)$", line)
        if (summary != None):
          testCount = int(summary.group(3))
          failCount = testCount - int(summary.group(2))
          failCounts[summary.group(1)] = failCount
          testCounts[summary.group(1)] = testCount
          globalFailCount = globalFailCount + failCount
          globalTestCount = globalTestCount + testCount
        print(line.strip())

    # Generate GTest-compatible XML
    with open(transcript) as inFile:
      for line in inFile:
        if (state == State.AWAIT_SUITE):
          m = re.search(r"^# INFO:\s+\[\d+\]\[(.*?)\]: RUNNING\s+$", line)
          if (m != None):
            suiteName = m.group(1)
            outFile.write(HEADER.format(globalTestCount, globalFailCount, suiteName, testCounts[suiteName], failCounts[suiteName]))
            state = State.AWAIT_TEST_BEGIN
        elif (state == State.AWAIT_TEST_BEGIN):
          m = re.search(r"^# INFO:\s+\[\d+\]\[(.*?)\]: RUNNING\s+$", line)
          if (m != None):
            suiteName = m.group(1)
            outFile.write(NEWSUITE.format(suiteName, testCounts[suiteName], failCounts[suiteName]))
            state = State.AWAIT_TEST_BEGIN
          else:
            m = re.search(r"^# INFO:\s+\[\d+\]\[(.*?)\]: (.*?)::RUNNING\s+$", line)
            if (m != None):
              errMsg = ''
              state = State.AWAIT_TEST_END
        elif (state == State.AWAIT_TEST_END):
          p = re.search(r"^# INFO:\s+\[\d+\]\[.*?\]: (.*?)::PASSED\s+$", line)
          f = re.search(r"^# INFO:\s+\[\d+\]\[.*?\]: (.*?)::FAILED\s+$", line)
          e = re.search(r"^# ERROR:\s+\[\d+\]\[.*?\]: (.*?)$", line)
          if (p != None):
            outFile.write('    <testcase name="{}" status="run" time="0" classname=""/>\n'.format(p.group(1)))  #, suiteName))
            state = State.AWAIT_TEST_BEGIN
          elif (f != None):
            outFile.write('    <testcase name="{}" status="run" time="0" classname="">\n'.format(f.group(1)))  #, suiteName))
            outFile.write('      <failure message="{}"><![CDATA[{}]]></failure>\n'.format(errMsg, errMsg))
            outFile.write('    </testcase>\n')
            state = State.AWAIT_TEST_BEGIN
          elif (e != None):
            errMsg = e.group(1)
    
    if (state != State.AWAIT_TEST_BEGIN):
      print('Illegal state: {}'.format(state), file=sys.stderr)
    
    outFile.write('  </testsuite>\n')
    outFile.write('</testsuites>\n')
