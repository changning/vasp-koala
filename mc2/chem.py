chem = open('chem_pot', 'w')
with open('data_all', 'r') as f:
    f.readline()    # get rid of first comment line
    lines = f.readlines()
    items = lines[0].split()
    if len(items) != 8:
        print 'This is not a binary alloy!\n'
        quit()
    e1, e2 = [float(x) for x in items[1:3]]
    n1a, n2a = int(items[4]), int(items[6])
    for i in range(1, len(lines)):
        items = lines[i].split()
        e1_old, e2_old = e1, e2
        e1, e2 = [float(x) for x in items[1:3]]
        n1a_old, n2a_old = n1a, n2a
        n1a, n1b, n2a, n2b = [int(x) for x in items[4:8]]
        n1, n2 = n1a + n1b, n2a + n2b
        if n1a - n1a_old == 0:
            continue
        mu1a = e1 / n1 + n1b / n1 * (e1 - e1_old) / (n1a - n1a_old)
        mu1b = e1 / n1 - n1a / n1 * (e1 - e1_old) / (n1a - n1a_old)
        mu2a = e2 / n2 + n2b / n2 * (e2 - e2_old) / (n2a - n2a_old)
        mu2b = e2 / n2 - n2a / n2 * (e2 - e2_old) / (n2a - n2a_old)
        chem.write('{}{:8.3f}{:8.3f}{:8.3f}{:8.3f}\n'.format(items[0], mu1a, mu1b, mu2a, mu2b))
chem.close()
