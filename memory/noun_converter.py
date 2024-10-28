from noun import * # make this a pip package some day
import sys

def cue_noun(data):
    x = cue(int.from_bytes(data[5:], 'little'))

    hed_len = (x.head.bit_length()+7)//8
    mark = x.head.to_bytes(hed_len,'little').decode()
    noun = x.tail
    return (mark,noun)


memory = [0]
bitmask = (1 << 28) -1
def inorder_traversal(noun):
    if(isinstance(noun,int)):
        print("error")
        return

    if(len(memory) == 1):
        memory.append(1<<63) # mark first cell as execute
    else:
        memory.append(0)
    
    #print(noun.pretty(True))
    #print("s\t\t"+' '.join(map(hex, memory)))
    if(isinstance(noun.head, Cell) and isinstance(noun.tail, Cell)):
        #print("\th: " +noun.head.pretty(False))
        #print("\tt: "+noun.tail.pretty(False))
        memory[-1] = memory[-1] | len(memory) << 28
        cell_loc = len(memory)-1
        inorder_traversal(noun.head)
        memory[cell_loc] = memory[cell_loc] | len(memory)
        inorder_traversal(noun.tail)
    elif(isinstance(noun.head, Cell) and isinstance(noun.tail, int)):
        #print("\th: "+ noun.head.pretty(False))
        #print("\tt: "+ str(noun.tail))
        memory[-1] = memory[-1] | (1<<56) | len(memory) << 28
        cell_loc = len(memory)-1
        inorder_traversal(noun.head)
        #print(cell_loc)
        #print(hex(memory[cell_loc]))
        memory[cell_loc] = memory[cell_loc] | (noun.tail & bitmask)
        #print(hex(memory[cell_loc]))
        #print("wtf")
    elif(isinstance(noun.head, int) and isinstance(noun.tail, Cell)):
        #print("\th: "+  str(noun.head))
        #print("\tt: "+noun.tail.pretty(False))
        memory[-1] = memory[-1] | (1<<57) | (noun.head & bitmask) << 28 | len(memory)
        inorder_traversal(noun.tail)
    elif(isinstance(noun.head, int) and isinstance(noun.tail, int)):
        #print("\th: "+  str(noun.head))
        #print("\tt: "+ str(noun.tail))
        memory[-1] = memory[-1] | (1<<57) | (1<<56) | (noun.head & bitmask) << 28 | (noun.tail & bitmask)

    #print("f\t\t"+' '.join(map(hex, memory)))

number = "59.500.485.596.334.891.570.437"

def main():
    # Check if two arguments (excluding the script name) are provided
    if len(sys.argv) != 3:
        print("Usage: python3 noun_converter.py <jammed-noun> <filename>")
        sys.exit(1)

    # Extract arguments
    number_str = sys.argv[1]
    filename = sys.argv[2]
    noun = None
    # Validate if the first argument is a number
    try:
        # Attempt to convert the number argument to a float
        number = int(number_str.replace('.',''))
        noun = cue(number)
        #pretty(noun, False)
        #print(noun)
    except ValueError:
        print("The first argument must be a number.")
        sys.exit(1)

    inorder_traversal(noun)
    memory[0] = len(memory)
    #for mem in memory:
    #    print(format(mem, '016x'))

    # Work with the file
    try:
        with open(filename, 'w') as file:
            for mem in memory:
                file.write(format(mem, '016x')+'\n')
    except IOError as e:
        print(f"An error occurred while working with the file: {e}")
        sys.exit(1)
    
if __name__ == "__main__":
    main()
