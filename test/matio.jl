# Test array of arrays
comp1 = [1 2; 3 4]
comp2 = [5 6 7; 8 9 10]
AB = Array{Int}[comp1, comp2]
write(fid, "AB", AB)
