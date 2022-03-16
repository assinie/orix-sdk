#!/usr/bin/python3
# vim: set ts=4 et:

# from pprint import pprint

import stat    # for file properties
import os      # for filesystem modes (O_RDONLY, etc)
import errno   # for error number codes (ENOENT, etc)

import sys

import argparse

__version__ = '0.2'

# pprint(args)


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


class Header:
    def __init__(self, file):

        signature = file.read(5)
        if signature != b'\x01\x00ori':
            return None

        self.filename = file.name
        self.header = bytearray(bytes(signature + file.read(15)))

    # def __repr__(self):

    def __str__(self):
        return '<Header file: %s, start: %04x, end: %04x, exec: %04x>' % (self.filename, self.start, self.end, self.exec)

    @property
    def raw(self):
        return self.header

    @property
    def signature(self):
        return self.header[0:5]

    @property
    def version(self):
        print('get version')
        return self.header[5]

    @version.setter
    def version(self, value):
        print('set version')

        if not isinstance(value, (float, int)):
            raise TypeError('Expected: float or int')

        if value != int(value):
            raise TypeError('Expected: non decimal value')

        value = int(value)
        if value <0 or value > 255:
            raise TypeError('Expected: 0 <= value < 256')

        self.header[5] = value

    @property
    def cpu(self):
        return self.header[6]

    @property
    def ostype(self):
        return self.header[7]

    @property
    def reserved(self):
        return self.header[8:13]

    @property
    def ftype(self):
        return self.header[13]

    @property
    def start(self):
        return self.header[14] + self.header[15] * 256

    @property
    def end(self):
        return self.header[16] + self.header[17] * 256

    @property
    def exec(self):
        return self.header[18] + self.header[19] * 256


# copy header and program and modify header

def Copyheader(ftap, binary_version, map):
    file = open(ftap, "rb")
    header = file.read()
    binary2 = list(header)
    binary2[5] = binary_version
    offsetmap = len(header) - 20

    # Set map offset
    lo = offsetmap & 0x00ff
    hi = offsetmap >> 8
    binary2[18] = lo
    binary2[19] = hi

    # Bitmap size
    sizemap = len(map)
    lo = sizemap & 0x00ff
    hi = sizemap >> 8
    binary2[7] = lo
    binary2[8] = hi

    return binary2


def Readheader(ftap):
    # header = Header(ftap)
    # print(header.raw)
    # header.version = 3
    # print(header.raw)
    # header.version = 4
    # print(header.raw)
    # print(header.__dict__)
    # ftap.seek(0,0)

    header = {}

    signature = ftap.read(5)

    if signature == b'\x01\x00ori':
        version = ord(ftap.read(1))
        cpu = ord(ftap.read(1))
        ostype = ord(ftap.read(1))
        reserved = ftap.read(5)
        fType = ord(ftap.read(1))

        fileStartAdr = ord(ftap.read(1)) + ord(ftap.read(1)) * 256
        fileEndAdr = ord(ftap.read(1)) + ord(ftap.read(1)) * 256
        fileExecAdr = ord(ftap.read(1)) + ord(ftap.read(1)) * 256

        header['signature'] = signature
        header['version'] = version
        header['cpu'] = cpu
        header['os'] = ostype
        header['reserved'] = reserved
        header['type'] = fType
        header['start'] = fileStartAdr
        header['end'] = fileEndAdr
        header['exec'] = fileExecAdr
        header['size']  = header['end']-header['start']+1

        return header

    return False


def Createheader(header, version, size):
    newheader = bytearray()

    newheader += header['signature']
    newheader.append(version)
    newheader.append(header['cpu'])

    # newheader.append(header['os'])
    # newheader += header['reserved']
    newheader += bytes([size % 256, size // 256])
    newheader += header['reserved'][1:]

    newheader.append(header['type'])
    newheader += bytes([header['start'] % 256, header['start'] // 256])
    newheader += bytes([header['end'] % 256, header['end'] // 256])
    newheader += bytes([header['size'] % 256, header['size'] // 256])

    # print(header)
    # print(newheader)

    return newheader


def diff(file1, file2, output, formatversion, color, verbose):
    i = 0
    s1 = ""
    s2 = ""
    offset_start = 0
    bitfieldmap = bytearray()
    offsetmap = bytearray()
    rawfile = bytearray()

    try:
        with open(file1, "rb") as f1:
            # On saute l'entete .tap
            header1 = Readheader(f1)
            if not header1:
                eprint("Fichier %s incorrect" % f1.name)
                exit(1)

            with open(file2, "rb") as f2:
                # On saute l'entete .tap
                header2 = Readheader(f2)
                if not header2:
                    eprint("Fichier %s incorrect" % f2.name)
                    exit(1)

                if header1['type'] != header2['type']:
                    eprint("Fichiers de type differents (%s:%#02X, %s:%#02X)" % (f1.name, header1['type'], f2.name, header2['type']))
                    exit(1)

                if header1['size'] != header2['size']:
                    eprint("Fichiers de tailles differentes (%s:%d, %s:%d)" % (f1.name, header1['size'], f2.name, header2['size']))
                    exit(1)

                if (header2['start'] - header1['start']) % 256:
                    eprint("Différence d'adresses non multiple de 256 (%s:$%04x, %s:$%04x)" % (f1.name, header1['start'], f2.name, header2['start']))
                    exit(1)

                if verbose:
                    print("Orix files:")
                    print("\t%s: size: %d, start: $%04x, end: $%04x " % (f1.name, header1['size'], header1['start'], header1['end']))
                    print("\t%s: size: %d, start: $%04x, end: $%04x " % (f2.name, header2['size'], header2['start'], header2['end']))
                    print()

                    print('    |    M A P    |%-24s|%-24s' % (f1.name, f2.name))
                    print('____|_____________|________________________|________________________')

                o = 0
                n = 0
                map = ""
                while i < header1['size']:
                    c1 = f1.read(1)
                    c2 = f2.read(1)

                    rawfile += c1

                    if not color:
                        s1 = s1 + "%02x " % ord(c1)
                        s2 = s2 + "%02x " % ord(c2)

                    if c1 != c2:
                        o += 2**(7 - i % 8)
                        if (output is not None) and (formatversion in [None,3]):
                            offsetmap.append(offset_start)

                        offset_start = 1
                        # Ordre inverse a cause de la boucle
                        # lda($00),x avec x=7 -> 0
                        # o += 2**(i%8)

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
                            # output.write(bytes([o]))
                            bitfieldmap.append(o)

                        if verbose:
                            print("%04X| %s %02X |%s|%s" % (i - 8, map, o, s1, s2))

                        s1 = ""
                        s2 = ""
                        map = ""
                        o = 0

                    offset_start = offset_start + 1
                    if offset_start > 255:
                        if formatversion == 3:
                            eprint("\nPanic : can't generate a binary with this version")
                            exit(1)

                        elif formatversion is None:
                            formatversion = 2

                # write last byte if any
                if s1 != '':
                    if output is not None:
                        bitfieldmap.append(o)

                    if color:
                        # Ajustement necessaire a cause des \e[xxm
                        s1 += '%*s' % ((8 - (i % 8)) * 3, ' ')

                    if verbose:
                        # print("%*s %02X |%-24s|%-24s" % (8-(i%8), ' ',o,s1,s2))
                        print("%04X| %s%*s %02X |%-24s|%-24s" % (i - (i % 8), map, 8 - (i % 8), ' ', o, s1, s2))

                if verbose:
                    print('____|_____________|________________________|________________________')
                    print('                      Size         %6d' % i)
                    print('                      Differences  %6d' % n)
                    print('____________________________________________________________________')

                if formatversion in (None, 2):
                    print("Format 2 overhead: ", header1['size']//8 + (1 if header1['size'] % 8 else 0), len(bitfieldmap))

                if formatversion in (None, 3):
                    print("Format 3 overhead: ", n, len(offsetmap))

                # Si aucun format n'est demandé, on choisi le meilleur (overhead le plus faible)
                if formatversion is None:
                    formatversion = (2, 3)[len(bitfieldmap) > len(offsetmap)]

                if output is not None:
                    print("Generate file ... ")
                    print("-Generate file version:", formatversion)

                    # Get header from first file
                    if formatversion == 2:
                        with open(output, "wb") as orixbinary:
                            orixbinary.write(Createheader(header1, formatversion, len(bitfieldmap)))
                            orixbinary.write(rawfile)
                            orixbinary.write(bitfieldmap)

                    elif formatversion == 3:
                        with open(output, "wb") as orixbinary:
                            orixbinary.write(Createheader(header1, formatversion, len(offsetmap)))
                            orixbinary.write(rawfile)
                            orixbinary.write(offsetmap)

            # f2.close()
        # f1.close()

    except (IOError, EOFError) as e:
        eprint(e)
        exit(e.errno)


def main():
    parser = argparse.ArgumentParser(prog='relocbin', description='Create an orix reloc binary file version 2 or 3', formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    # parser.add_argument('binaryfileversion1', type=str, metavar='binaryfileversion1', help='filename to diff')
    # parser.add_argument('binaryreferencefileversion1', type=str, metavar='binaryreferencefileversion1', help='filename to diff')
    # parser.add_argument('file', type=str, nargs=2, help='filename to diff')
    parser.add_argument('file1', type=str, help='filename to diff (reference)')
    parser.add_argument('file2', type=str, help='filename to diff')

    # parser.add_argument('--output', '-o', type=argparse.FileType('wb'), default=sys.stdout, help='MAP filename')
    # parser.add_argument('outputfile', type=str, help='Output binaryfile')
    parser.add_argument('-o', '--output', dest='outputfile', type=str, help='Output binary file')

    # parser.add_argument('formatversion', type=int, choices=range(2, 4), metavar='formatversion', help='Format version ')
    group = parser.add_mutually_exclusive_group(required=False)
    group.add_argument('-2', '--bitmap', dest='formatversion', action='store_const', const=2, help='format version 2')
    group.add_argument('-3', '--offset', dest='formatversion', action='store_const', const=3, help='format version 3')

    parser.add_argument('--color', '-c', default=False, action='store_true', help='color output')
    parser.add_argument('--verbose', '-v', default=False, action='store_true', help='verbose mode')
    parser.add_argument('--version', '-V', action='version', version='%%(prog)s v%s' % __version__)

    args = parser.parse_args()

    diff(args.file1, args.file2, args.outputfile, args.formatversion, args.color, args.verbose)

    # print(args)


if __name__ == '__main__':
    main()
