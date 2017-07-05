# output files
data = open('data_all', 'w')
rej  = open('data_rej', 'w')
# get all elements 
with open('../POSCARs/POSCAR_0001_a') as f:
    elems = f.readlines()[5].split()
with open('../POSCARs/POSCAR_0001_b') as f:
    elems += f.readlines()[5].split()
elem = []
for i in elems:
    if i not in elem:
        elem.append(i)
data.write('# index E_1 E_2 E_tot')
for x in range(0,2):
    for i in elem:
        data.write('  {}'.format(i))
data.write('\n')
rej.write('# index E_1 E_2 E_tot\n')

# collect 
with open('../Etot.txt') as f:
    for line in f:
        w = line.split()
        if line[0] != '#':
            s = "  ".join(w[:4])
            pos1 = '../POSCARs/POSCAR_' + w[0] + '_a'
            pos2 = '../POSCARs/POSCAR_' + w[0] + '_b'
            with open(pos1) as f1:
                f1_lines = f1.readlines()
                for x in range(0, len(elem)):
                    this_elems = f1_lines[5].split()
                    this_num = this_elems.index(elem[x]) if elem[x] in this_elems else -1
                    if this_num > -1:
                        this_count = f1_lines[6].split()[this_num]
                        s += '{:5d}'.format(int(this_count))
                    else:
                        s += '{:5d}'.format(0)
            with open(pos2) as f1:
                f1_lines = f1.readlines()
                for x in range(0, len(elem)):
                    this_elems = f1_lines[5].split()
                    this_num = this_elems.index(elem[x]) if elem[x] in this_elems else -1
                    if this_num > -1:
                        this_count = f1_lines[6].split()[this_num]
                        s += '{:5d}'.format(int(this_count))
                    else:
                        s += '{:5d}'.format(0)
            data.write(s + '\n')
            num = w[0]
        else:
            rej.write(num + "  ")
            rej.write("  ".join(w[1:4]) + "\n")
data.close()
rej.close()
