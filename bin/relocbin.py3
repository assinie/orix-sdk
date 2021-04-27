#!/usr/bin/python3

# from pprint import pprint

import stat    # for file properties
import os      # for filesystem modes (O_RDONLY, etc)
import errno   # for error number codes (ENOENT, etc)
               # - note: these must be returned as negatives
import sys

import argparse

__version__ = '0.1'

# pprint(args)

#copy header and program and modify header
def CopyHeader(ftap,binary_version,map):
	file=open(ftap,"rb")
	Header=file.read()
	binary2=list(Header)
	binary2[5]=binary_version
	offsetmap=len(Header)-20
	# Set map offset
	lo = offsetmap & 0x00ff
	hi = offsetmap  >> 8
	binary2[18]=lo
	binary2[19]=hi
	
	sizemap=len(map) #Size map
	lo = sizemap & 0x00ff
	hi = sizemap  >> 8
	binary2[7]=lo
	binary2[8]=hi
	return binary2



def ReadHeader(ftap):
	Header = {}
	b = ftap.read(5)
	if b == b'\x01\x00ori':
		#version
		version = ftap.read(1)
		cpu = ord(ftap.read(1))
		ostype = ord(ftap.read(1))
		reserved = ftap.read(5) 
		fType = ord(ftap.read(1))
		fileStartAdrLow=ftap.read(1)
		fileStartAdrHigh=ftap.read(1)
					
		fileStartAdr = ord(fileStartAdrHigh)*256 + ord(fileStartAdrLow)
		fileEndAdr = ord(ftap.read(1))*256 + ord(ftap.read(1))
		fileExecAdr = ord(ftap.read(1))*256 + ord(ftap.read(1))

		Header['os'] = ostype
		Header['cpu'] = cpu
		Header['type'] = fType
		Header['start'] = fileStartAdr
		Header['end'] = fileEndAdr
		Header['exec'] = fileExecAdr
		allsize=ftap.read()
		Header['size'] = ftap.tell()-20
		ftap.seek(20,0)
		print("Orix file")
		print("Size %d : start : %d, end %d ",Header['size'],fileStartAdr,fileEndAdr)
		return Header

	return False

def diff(file1, file2, output, formatversion, color):
	i = 0
	s1 = ""
	s2 = ""
	offset_start = 0
	bitfield=[]
	bitfieldmap= bytearray()
	offsetmap=bytearray()
	

	orixbinary=open(output,"wb")
	orixbitfield=open("bitfield","wb")

	with open(file1,"rb") as f1:
		# On saute l'entete .tap
		Header1 = ReadHeader(f1)
		if not Header1:
			print("Fichier %s incorrect" % f1.name)
			exit(1)

		with open(file2,"rb") as f2:
			# On saute l'entete .tap
			Header2 = ReadHeader(f2)
			if not Header2:
				print("Fichier %s incorrect" % f2.name)
				exit(1)

			if Header1['type'] != Header2['type']:
				print("Fichiers de type differents (%s:%#02X, %s:%#02X)" % (f1.name,Header1['type'], f2.name, Header2['type']))
				exit(1)

			if Header1['size'] != Header2['size']:
				print("Fichiers de tailles differentes (%s:%d, %s:%d)" % (f1.name,Header1['size'], f2.name, Header2['size']))
				exit(1)

			print('    |    M A P    |%-24s|%-24s' % (f1.name, f2.name))
			print('____|_____________|________________________|________________________')
			o = 0
			n = 0
			map = ""
			while i< Header1['size']:
				c1=f1.read(1)
				c2=f2.read(1)

				if not color:
					s1 = s1 + "%02x " % ord(c1)
					s2 = s2 + "%02x " % ord(c2)

				if c1 != c2:
					o += 2**(7-i%8)
					if output is not None:
						offsetmap.append(offset_start)
				
					offset_start=1
					# Ordre inverse a cause de la boucle
					# lda($00),x avec x=7 -> 0
					#o += 2**(i%8)

					n += 1
					map += '*'
					# 'print('*',end="")

					if color:
						# s1 = s1 + "%c[1;47;31m%02x%c[0;30m " % (27, ord(c1), 27)
						# s2 = s2 + "%c[1;47;31m%02x%c[0;30m " % (27, ord(c2), 27)
						s1 = s1 + "%c[1;47;31m%02x%c[0;38m " % (27, ord(c1), 27)
						s2 = s2 + "%c[1;47;31m%02x%c[0;38m " % (27, ord(c2), 27)

				else:
					map += '.'
					# print('.',end="")

					if color:
						s1 = s1 + "%02x " % ord(c1)
						s2 = s2 + "%02x " % ord(c2)

				i += 1
				
				if i % 8 == 0:
					if output is not None:
						print("Byte : ",bytes([o]))
						#output.write(bytes([o]))
						bitfield.append(bytes([o]))
						bitfieldmap.append(o)

					print("%04X| %s %02X |%s|%s" % (i-8,map,o,s1,s2))
					s1 = ""
					s2 = ""
					map = ""
					o = 0
				offset_start=offset_start+1
				if offset_start>255:
					print("Panic : can't generate a binary with this version")
					exit()

			if s1!= '':
				if color:
					# Ajustement necessaire a cause des \e[xxm
					s1 += '%*s' % ((8-(i%8))*3, ' ')

				# print("%*s %02X |%-24s|%-24s" % (8-(i%8), ' ',o,s1,s2))
				print("%04X| %s%*s %02X |%-24s|%-24s" % (i-(i%8),map, 8-(i%8), ' ',o,s1,s2))

			print('____|_____________|________________________|________________________')
			print('                      Size         %6d' % i)
			print('                      Differences  %6d' % n)
			print('____________________________________________________________________')
			# write end of file

			end_byte=0
			print("Generate file ... ")
			print("-Generate file version",formatversion)
			# Binary version 1 : byte offset
			if i % 8 != 0:
				bitfield.append(o)
				bitfieldmap.append(o)

			if formatversion==2:
				orixbinary.write(bytearray(CopyHeader(file1,formatversion,bitfieldmap))) 
				orixbinary.write(bitfieldmap)
				orixbitfield.write(bitfieldmap)

			if formatversion==3:
				orixbinary.write(bytearray(CopyHeader(file1,formatversion,offsetmap))) 
				orixbinary.write(offsetmap) 
			# Get header from first file
		f2.close()
	f1.close()


def main():
	parser = argparse.ArgumentParser(prog='relocbin', description='Create an orix reloc binary file version 2 or 3', formatter_class=argparse.ArgumentDefaultsHelpFormatter)

	parser.add_argument('binaryfileversion1', type=str, metavar='binaryfileversion1', help='filename to diff')
	parser.add_argument('binaryreferencefileversion1', type=str,  metavar='binaryreferencefileversion1', help='filename to diff')
	# parser.add_argument('--output', '-o', type=argparse.FileType('wb'), default=sys.stdout, help='MAP filename')
	parser.add_argument('outputfile', type=str, metavar='outputfile', help='Output binaryfile')
	parser.add_argument('formatversion', type=int, choices=range(2, 4), metavar='formatversion', help='Format version ')
	parser.add_argument('--color', '-c', default=False, action='store_true', help='Color output')
	parser.add_argument('--version', '-v', action='version', version= '%%(prog)s v%s' % __version__)

	args = parser.parse_args()

	diff(args.binaryfileversion1, args.binaryreferencefileversion1, args.outputfile, args.formatversion, args.color)

if __name__ == '__main__':
	main()
