"""
Urbit nouns with mug, jam, and cue.
"""

import mmh3
from bitstream import BitStream

def byte_length(i: int):
    """how many bytes to represent i?

    >>> byte_length(0)
    0
    >>> byte_length(255)
    1
    >>> byte_length(256)
    2
    """

    lyn = i.bit_length()
    byt = lyn >> 3
    return byt + 1 if lyn & 7 else byt

def intbytes(i: int):
    """turn i into a (little endian) bytes object

    >>> intbytes(0)
    b''
    >>> intbytes(256)
    b'\\x00\\x01'
    """

    return i.to_bytes(byte_length(i), 'little', signed=False)

def mum(syd: int, fal: int, key: int):
    """try to hash key with syd, incrementing syd on zero
    hash up to 8 times, falling back to fal.

    >>> mum(0xcafebabe, 0x7fff, 0)
    2046756072
    >>> mum(0xdeadbeef, 0xfffe, 8790750394176177384)
    422532488
    """

    k = intbytes(key)
    for s in range(syd, syd+8):
        haz = mmh3.hash(k, seed=s, signed=False)
        ham = (haz >> 31) ^ (haz & 0x7fffffff)
        if 0 != ham:
            return ham
    return fal

def mug_both(one: int, two: int):
    """mug from two other mugs (for cells)

    >>> mug_both(2046756072, 2046756072)
    422532488
    """

    return mum(0xdeadbeef, 0xfffe, (two << 32) | one)

class Cell:
    """A cell is an ordered pair of two nouns.
    >>> x = Cell(1, Cell(2, 3))
    >>> x.head
    1
    >>> x.tail.head
    2
    >>> x.tail.tail
    3
    """

    def __init__(self, head, tail, mug=0):
        self.head = head
        self.tail = tail
        self.mug = mug

    def __hash__(self):
        """31-bit non-zero murmur3 (mug)

        >>> x = Cell(0, 0)
        >>> x.mug
        0
        >>> hash(x)
        422532488
        >>> x.mug
        422532488
        """

        if 0 == self.mug:
            self.mug = mug_both(mug(self.head), mug(self.tail))
        return self.mug

    def __eq__(self, other):
        """unifying equality: after comparing equal, cells share storage.

        >>> x = Cell(Cell(1,2),Cell(3,4))
        >>> y = Cell(Cell(1,2),Cell(3,4))
        >>> hash(y)
        1496649457
        >>> x.head is y.head or x.tail is y.tail
        False
        >>> x == y
        True
        >>> x.head is y.head and x.tail is y.tail
        True
        >>> x.mug != 0 and x.mug == y.mug
        True
        """

        if not deep(other):
            return False
        if self.mug != 0 and other.mug != 0 and self.mug != other.mug:
            return False
        if self.head != other.head:
            return False
        other.head = self.head
        if self.tail != other.tail:
            return False
        other.tail = self.tail
        if 0 != self.mug:
            other.mug = self.mug
        elif 0 != other.mug:
            self.mug = other.mug
        return True

    def pretty(self, tail_pos):
        """pretty print a cell in or out of tail position

        >>> x = Cell(0, 0)
        >>> x.pretty(False)
        '[0 0]'
        >>> x.pretty(True)
        '0 0'
        """

        content = '%s %s' % \
                (pretty(self.head, False), pretty(self.tail, True))
        if tail_pos:
            return content
        return '[%s]' % content

    def __str__(self):
        return self.pretty(False)

noun = int | Cell

def deep(n: noun):
    """test whether noun is a cell, like nock 3
    
    >>> deep(1)
    False
    >>> deep(Cell(1,2))
    True
    """
    
    return isinstance(n, Cell)

def mug(n: noun):
    """get the mug for any noun

    >>> mug(0)
    2046756072
    >>> mug(Cell(0, 0))
    422532488
    """

    if deep(n):
        return hash(n)
    return mum(0xcafebabe, 0x7fff, n)

def pretty(n: noun, tail_pos:bool):
    """pretty-print a noun, in or out of tail position.

    >>> pretty(1, True)
    '1'
    >>> pretty(Cell(1,Cell(2,3)), False)
    '[1 2 3]'
    >>> pretty(Cell(Cell(1,2), 3), True)
    '[1 2] 3'
    """

    if deep(n):
        return n.pretty(tail_pos)
    return str(n)

def translate(seq):
    """turn python sequences into tuples.

    >>> str(translate([1,[2,3],4]))
    '[1 [2 3] 4]'
    """

    def r(i, l):
        if 1 == l:
            return seq[i]
        return Cell(translate(seq[i]), r(i+1, l-1))

    if isinstance(seq, noun):
        return seq
    c = len(seq)
    if 0 == c:
        return 0
    return r(0, c)

def parse(s: str):
    """parse strings into nouns. dots in atoms are ignored,
    outermost braces can be omitted.

    >>> parse('1.024')
    1024
    >>> x = parse('[[1 2] 3]')
    >>> [x.head.head, x.head.tail, x.tail]
    [1, 2, 3]
    >>> x = parse('[1 2] 3')
    >>> [x.head.head, x.head.tail, x.tail]
    [1, 2, 3]
    """

    sep = True
    start = 0
    wait = []
    top = (0, [])
    num = []

    def frame(i: int):
        return (i, [])

    def end_atom():
        nonlocal sep
        if not sep:
            sep = True
            top[1].append(int(''.join(num)))
            num.clear()

    def end_cell():
        items = top[1]
        count = len(items)
        if 0 == count:
            return 0
        count -= 1
        tail = items[count]
        while count > 0:
            count -= 1
            tail = Cell(items[count], tail)
        return tail

    for i in range(0, len(s)):
        c = s[i]
        match c:
            case '[':
                end_atom()
                wait.append(top)
                top = frame(i)
            case ']':
                if not wait:
                    raise ValueError('unmatched ] at %d' % i)
                end_atom()
                val = end_cell()
                top = wait.pop()
                top[1].append(val)
            case ' ':
                end_atom()
            case '.':
                if sep:
                    raise ValueError('floating dot at %d' % i)
            case _:
                if not str.isdigit(c):
                    raise ValueError('unrecognized character %s at %d' % (c, i))
                else:
                    if sep:
                        start = i
                        sep = False
                    num.append(c)
    if wait:
        raise ValueError('unclosed [ at %d' % top[0])
    end_atom()
    return end_cell()

def jam_to_stream(n: noun, out: BitStream):
    """jam but put the bits into a stream

    >>> s = BitStream()
    >>> jam_to_stream(Cell(0,0), s)
    >>> s
    100101
    """

    cur = 0
    refs = {}

    def bit(b: bool):
        nonlocal cur
        out.write(b, bool)
        cur += 1

    def zero():
        bit(False)

    def one():
        bit(True)

    def bits(num: int, count: int):
        nonlocal cur
        for i in range(0, count):
            out.write(0 != (num & (1 << i)), bool)
        cur += count

    def save(a: noun):
        refs[a] = cur

    def mat(i: int):
        if 0 == i:
            one()
        else:
            a = i.bit_length()
            b = a.bit_length()
            above = b + 1
            below = b - 1
            bits(1 << b, above)
            bits(a & ((1 << below) - 1), below)
            bits(i, a)

    def back(ref: int):
        one()
        one()
        mat(ref)

    def r(a: noun):
        dupe = refs.get(a)
        if deep(a):
            if dupe:
                back(dupe)
            else:
                save(a)
                one()
                zero()
                r(a.head)
                r(a.tail)
        elif dupe:
            isize = a.bit_length()
            dsize = dupe.bit_length()
            if isize < dsize:
                zero()
                mat(a)
            else:
                back(dupe)
        else:
            save(a)
            zero()
            mat(a)
    r(n)

def read_int(length: int, s: BitStream):
    """read length bits from s and make a python integer.

    >>> s = BitStream()
    >>> s.write(False, bool)
    >>> s.write(False, bool)
    >>> s.write(True, bool)
    >>> read_int(3, s)
    4
    """

    r = 0
    for i in range(0, length):
        r |= s.read(bool) << i
    return r

def jam(n: noun):
    """urbit serialization: * -> @

    >>> jam(0)
    2
    >>> jam(Cell(0,0))
    41
    >>> jam(Cell(Cell(1234567890987654321,1234567890987654321), \\
    ...          Cell(1234567890987654321,1234567890987654321)))
    22840095095806892874257389573
    """

    out = BitStream()
    jam_to_stream(n, out)
    return read_int(len(out), out)

def cue_from_stream(s: BitStream):
    """cue but read the bits from a stream

    >>> s = BitStream()
    >>> s.write(False, bool)
    >>> s.write(True, bool)
    >>> cue_from_stream(s)
    0
    """

    refs = {}
    cur = 0

    def bits(n: int):
        nonlocal cur
        cur += n
        return read_int(n, s)

    def one():
        nonlocal cur
        cur += 1
        x= s.read(bool)
        return x
    
    def rub():
        z = 0
        while not one():
            z += 1
        if 0 == z:
            return 0
        below = z - 1
        lbits = bits(below)
        bex = 1 << below
        return bits(bex ^ lbits)

    def r(start: int):
        ret = None
        if one():
            if one():
                ret = refs[rub()]
            else:
                hed = r(cur)
                tal = r(cur)
                ret = Cell(hed, tal)
        else:
            ret = rub()
        refs[start] = ret
        return ret
    return r(cur)

def cue(i: int):
    """urbit deserialization: @ -> *

    >>> str(cue(22840095095806892874257389573))
    '[[1234567890987654321 1234567890987654321] 1234567890987654321 1234567890987654321]'
    """

    s = BitStream()
    while i > 0:
        s.write(i & 1, bool)
        i >>= 1
    return cue_from_stream(s)

if '__main__' == __name__:
    import doctest
    doctest.testmod()
