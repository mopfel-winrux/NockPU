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
            exec_field = (exec_bits >> 5) & 0x01  # Most significant bit
            stack_field = (exec_bits >> 4) & 0x01  # 2nd most significant bit
            remaining_exec_bits = exec_bits & 0x0F  # Remaining 4 bits
            hed_tag = (tag_bits >> 1) & 0x01  # 7th bit
            tel_tag = tag_bits & 0x01  # Last bit
            hed_bits = (decimal_value >> 28) & 0xFFFFFFF  # Next 28 bits
            tel_bits = decimal_value & 0xFFFFFFF  # Last 28 bits
            # Store in dictionary
            hex_dict[decimal_key] = {
                'exec': exec_field,
                'stack': stack_field,
                'remaining_exec_bits': remaining_exec_bits,
                'hed_tag': hed_tag,
                'tel_tag': tel_tag,
                'hed_bits': hed_bits,
                'tel_bits': tel_bits
            }
    return hex_dict


file_path = 'gc_3_before'
init_addr=0x1

#file_path = 'gc_3'
#init_addr=0x401

mem = read_hex_file(file_path)


def read_mem(addr):
    cur = mem[addr]
   
    tag = ''
    if(cur['exec'] == 1 and cur['stack'] == 0):
        tag = '*'
    elif(cur['exec'] == 1 and cur['stack'] == 1):
        tag = '-'

#    tag = ''

    #Both atoms
    if(cur['hed_tag']==1 and cur['tel_tag']==1):
        if(cur['tel_bits'] == NIL):
            return cur['hed_bits']
        return Cell(cur['hed_bits'], cur['tel_bits'], tag = tag)

    #hed is cell
    if(cur['hed_tag']==0 and cur['tel_tag']==1):
        return Cell(read_mem(cur['hed_bits']), cur['tel_bits'], tag = tag)

    #tel is cell
    if(cur['hed_tag']==1 and cur['tel_tag']==0):
        return Cell(cur['hed_bits'], read_mem(cur['tel_bits']), tag = tag)

    #both cells
    if(cur['hed_tag']==0 and cur['tel_tag']==0):
        return Cell(read_mem(cur['hed_bits']), read_mem(cur['tel_bits']), tag = tag)
    
n = read_mem(init_addr)

print(n.pretty(False))
