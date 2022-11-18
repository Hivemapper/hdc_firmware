#!/usr/bin/python3
#
# ublox_data_util.py
#
# Python utility for pushing  
#
# Copyright 2022 Hellbender Inc.
#
# Changelog:
# Author Email, Date,     , Comment
# niessl      , 2022-09-16, Created File
#
#

import argparse
import os
#import serial
import sys
import time

def init_args():
  parser = argparse.ArgumentParser(
    usage="%(prog)s -d [SERIAL DEVICE] -i [INPUT FILE] -o [OUTPUT FILE]",
    description="Take contents of an input file and write them to a serial device"
  )
  parser.add_argument(
    "-d", "--device", help = "Device destination (/dev/ttyAMA1)")
  parser.add_argument(
    "-b", "--baudrate", help = "Baudrate of devivce. (38400)")    
  parser.add_argument(
    "-i", "--input",  help = "Source input to transfer over.")
  parser.add_argument(
    "-o", "--output", help = "Destination to write output")
  parser.add_argument(
    "-m", "--maxBytes", help = "Maximum number of bytes to capture from ublox")
  parser.add_argument(
    "-s", "--blockSize", help = "Number of bytes to transfer per cycle to ublox")

  args = parser.parse_args()
  entries = vars(args)
  if entries['device'] == None:
    entries['device'] = '/dev/ttyAMA1'
  if entries['baudrate'] == None:
    entries['baudrate'] = 38400  
  if entries['maxBytes'] == None:
    entries['maxBytes'] = 1024
  if entries['blockSize'] == None:
    entries['blockSize'] = 128
  
  return vars(args)

def init_connect(targetDevice, targetBaudrate):
  '''ser = serial.Serial(
	  port=targetDevice,
	  baudrate=targetBaudrate,
	  parity=serial.PARITY_NONE,
	  stopbits=serial.STOPBITS_ONE,
	  bytesize=serial.SEVENBITS
  )
  ser.open()'''
  ser = os.open(targetDevice, os.O_RDWR)
  
  return ser

def listen_and_record(serialConnection, destination):
  out = os.read(serialConnection, 1024)
  readBytes = len(out)
  if readBytes > 0:
    if destination is not None:
      destination.write(out)
  return readBytes;

def read_and_store_source(source):
  sourceFile = open(source, "r+b")
  sourceContent = sourceFile.read()
  if sourceContent[-2] != 10 or sourceContent[-1] != 14:
    if sourceContent[-1] == 10 or sourceContent[-1] == 14:
      sourceContent = sourceContent[:-1]
    sourceContent = sourceContent + b'\r\n'
  return sourceContent
  
def read_and_send(serialConnection, source, index, maxBytes):
  end = index + maxBytes
  sliceToSend = None
  if end > len(source):
    sliceToSend = source[index:]
  else:
    sliceToSend = source[index:end]
  return os.write(serialConnection, sliceToSend)

if __name__ == "__main__":
  bytesWritten = 0
  bytesRead = 0
  
  bytesToWrite = 0
  bytesToRead = 0
  
  entries = init_args()
  outputDest = None
  writeSource = None  
  serialHandler = init_connect(entries['device'], entries['baudrate'])
  
  if entries['input'] is not None:
    writeSource = read_and_store_source(entries['input'])
    bytesToWrite = len(writeSource)
  
  if entries['output'] is not None:
    bytesToRead = entries['maxBytes']
    outputDest = open(entries['output'],'w+b')

  while (bytesWritten < bytesToWrite) or (bytesRead < bytesToRead):
    if bytesRead < bytesToRead:
      bytesRead = bytesRead + listen_and_record(serialHandler, outputDest)
    if bytesWritten < bytesToWrite:
      bytesWritten = bytesWritten + read_and_send(serialHandler, writeSource, bytesWritten, entries['blockSize'])
    time.sleep(1)
    print("read: {}/{}, written: {}/{}".format(bytesRead, bytesToRead, bytesWritten, bytesToWrite))
  if outputDest is not None:
    outputDest.close()  
  

