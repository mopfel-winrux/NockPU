from noun import * # make this a pip package some day
import sys

NIL = 0xFFFFFFF

def read_hex_file(file_path):
    hex_dict = {}
    with open(file_path, 'r') as file:
        for line in file:
            key, value = line.strip().split()
            # Convert hex values to decimal
            decimal_key = int(key, 16)
            decimal_value = int(value, 16)
            # Extract parts
            tag_bits = (decimal_value >> 56) & 0xFF  # First 8 bits
            exec_bits = (tag_bits >> 2) & 0x3F  # First 6 bits
            hed_tag = (tag_bits >> 1) & 0x01  # 7th bit
            tel_tag = tag_bits & 0x01  # Last bit
            hed_bits = (decimal_value >> 28) & 0xFFFFFFF  # Next 28 bits
            tel_bits = decimal_value & 0xFFFFFFF  # Last 28 bits
            # Store in dictionary
            hex_dict[decimal_key] = {
                'exec_bits': exec_bits,
                'hed_tag': hed_tag,
                'tel_tag': tel_tag,
                'hed_bits': hed_bits,
                'tel_bits': tel_bits
            }
    return hex_dict

file_path = 'gc_2_before'
file_path = 'gc_2'
mem = read_hex_file(file_path)

init_addr=0x401
#init_addr=0x1

def read_mem(addr):
    cur = mem[addr]

    #Both atoms
    if(cur['hed_tag']==1 and cur['tel_tag']==1):
        if(cur['tel_bits'] == NIL):
            return cur['hed_bits']
        return Cell(cur['hed_bits'], cur['tel_bits'])

    #hed is cell
    if(cur['hed_tag']==0 and cur['tel_tag']==1):
        return Cell(read_mem(cur['hed_bits']), cur['tel_bits'])

    #tel is cell
    if(cur['hed_tag']==1 and cur['tel_tag']==0):
        return Cell(cur['hed_bits'], read_mem(cur['tel_bits']))

    #both cells
    if(cur['hed_tag']==0 and cur['tel_tag']==0):
        return Cell(read_mem(cur['hed_bits']), read_mem(cur['tel_bits']))
    
n = read_mem(init_addr)

print(n.pretty(False))
