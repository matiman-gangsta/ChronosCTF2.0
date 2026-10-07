FLAG = "CHRONOS{4c8d2e1f-7b3a-4950-86c1-9e2f3a4b5c6d}"
PASSWORD = "Xor_Rotate_Key99"

def rotl8(v, r):
    r %= 8
    return ((v << r) | (v >> (8 - r))) & 0xFF

target = []
for i, ch in enumerate(PASSWORD):
    c = ord(ch)
    x = c ^ 0x5A
    r = rotl8(x, (i % 4) + 1)
    target.append(r)

enc_flag = []
for i, ch in enumerate(FLAG):
    key_ch = ord(PASSWORD[i % len(PASSWORD)])
    enc_flag.append(ord(ch) ^ key_ch)

def c_array(name, arr):
    body = ", ".join(f"0x{b:02x}" for b in arr)
    return f"unsigned char {name}[] = {{{body}}};"

print(c_array("target", target))
print(c_array("enc_flag", enc_flag))
print(f"// PASSWORD (secreta, NO va en el binario en texto plano): {PASSWORD}")
print(f"// target length: {len(target)}, enc_flag length: {len(enc_flag)}")
