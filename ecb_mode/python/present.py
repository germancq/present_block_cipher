#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : present.py
# Author            : German C.Quiveu <germancq@dte.us.es>
# Date              : 17.06.2026
# Last Modified Date: 17.06.2026
# Last Modified By  : German C.Quiveu <germancq@dte.us.es>

"""
key : 80 bits
plaintext : 64 bits
block cipher : 64 bits

"""

from collections import deque

from bitstring import BitArray

S_box = [0xC, 0x5, 0x6, 0xB, 0x9, 0x0, 0xA,
         0xD, 0x3, 0xE, 0xF, 0x8, 0x4, 0x7, 0x1, 0x2]
S_box_dec = [
    0x5,
    0xE,
    0xF,
    0x8,
    0xC,
    0x1,
    0x2,
    0xD,
    0xB,
    0x4,
    0x6,
    0x3,
    0x0,
    0x7,
    0x9,
    0xA,
]


class Present:

    def __init__(self, key):
        # print("=======================================")
        # print(hex(key))
        # print("=========================================")
        self.round_keys = generate_round_keys(key)

    def decrypt(self, ciphertext):

        state = ciphertext

        # print("////////////////////////////")

        for i in range(1, 32):
            # print(i)
            state = addRoundKey(state, self.round_keys[32 - i])
            # print(hex(state))
            # print(hex(round_keys[]))
            state = pLayer_dec(state)
            # print(hex(state))
            state = s_box_dec(state)
            # print(hex(state))

        state = addRoundKey(state, self.round_keys[0])

        # print(hex(state))
        # print("////////////////////////////")
        return state

    def encrypt(self, plaintext):

        state = plaintext
        # print("-------------------------------------")
        # print(hex(plaintext))
        for i in range(1, 32):
            # print(i)
            state = addRoundKey(state, self.round_keys[i - 1])
            # print(hex(state))
            # print(hex(self.round_keys[i]))
            state = s_box_enc(state)
            # print(hex(state))
            state = pLayer_enc(state)
            # print(hex(state))

        state = addRoundKey(state, self.round_keys[31])

        # print(hex(state))
        # print("---------------------------------------")
        return state

    def refresh_key(self, key):
        self.round_keys = generate_round_keys(key)


def generate_round_keys(key):
    round_keys = []
    new_key = key
    round_keys.append(key >> 16)
    for i in range(1, 31 + 1):
        new_key = update_key(new_key, i)
        round_keys.append(new_key >> 16)

    return round_keys


def bitArray_to_int_value(bitarray):
    value = 0
    for i in range(0, len(bitarray)):
        value = value + (2**i) * bitarray[i]

    return value


def addRoundKey(state, key):
    # XOR leftmost 64 bits from key with current stat

    return state ^ key


def update_key(key, round_counter):
    new_key = 0

    new_key = key >> 19
    # print(hex(new_key))
    # print(hex(((key & 0x7FFFF) << 61)))
    new_key = new_key + ((key & 0x7FFFF) << 61)
    # print(hex(new_key))

    S_indx = (new_key >> 76) & 0xF
    new_key = (new_key & (2**76 - 1)) + (S_box[S_indx] << 76)
    # print(hex(new_key))

    new_key = new_key ^ (round_counter << 15)
    # print(hex(new_key))

    return new_key


def s_box_enc(state):
    new_state = 0x0
    for i in range(0, 16):
        S_indx = (state >> i * 4) & 0xF
        new_state = new_state + (S_box[S_indx] << i * 4)
    return new_state


def s_box_dec(state):
    new_state = 0x0
    for i in range(0, 16):
        S_indx = (state >> i * 4) & 0xF
        new_state = new_state + (S_box_dec[S_indx] << i * 4)
    return new_state


def pLayer_enc(state):
    new_state = 0x0

    for i in range(0, 63):
        # new_state[pLayer[i]] = state[i]
        permutation_value = i * 16 % 63
        bit_original = (state >> i) & 0x1
        new_state = new_state + (bit_original << permutation_value)

    bit_original = (state >> 63) & 0x1
    new_state = new_state + (bit_original << 63)
    return new_state


def pLayer_dec(state):
    new_state = 0x0

    for i in range(0, 63):
        # new_state[pLayer[i]] = state[i]
        permutation_value = i * 16 % 63
        bit_original = (state >> permutation_value) & 0x1
        new_state = new_state + (bit_original << i)

    bit_original = (state >> 63) & 0x1
    new_state = new_state + (bit_original << 63)
    return new_state


if __name__ == "__main__":
    # present_impl = Present(0x00000000000000000000)
    present_impl = Present(0x4321)

    present_impl.encrypt(0x0000000000000000)
    # present_impl.decrypt(0x5579c1387b228445)
