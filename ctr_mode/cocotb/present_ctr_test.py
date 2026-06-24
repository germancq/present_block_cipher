#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : present_ctr_test.py
# Author            : German C.Quiveu <germancq@dte.us.es>
# Date              : 17.06.2026
# Last Modified Date: 17.06.2026
# Last Modified By  : German C.Quiveu <germancq@dte.us.es>

import importlib
import os
import random
import sys
import time

import cocotb
import numpy as np
import present_ctr
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import FallingEdge, RisingEdge, Timer

home = os.getenv("HOME")


CLK_PERIOD = 20  # 50 MHz
SIGNATURE = 0xAABBCCDD
KEY_LEN = 80
IV_LEN = 64
BLOCK_LEN = 64
# the keyword await
#   Testbenches built using Cocotb use coroutines.
#   While the coroutine is executing the simulation is paused.
#   The coroutine uses the await keyword
#   to pass control of execution back to
#   the simulator and simulation time can advance again.
#
#   await return when the 'Trigger' is resolve
#
#   Coroutines may also await a list of triggers
#   to indicate that execution should resume if any of them fires


def setup_function(dut, key, IV, block_i, num_block):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD, unit="ns").start())
    dut.rst.value = 0
    dut.key.value = key
    dut.IV.value = IV
    dut.block_i.value = block_i
    dut.block_number.value = num_block
    dut.rq_data.value = 0


async def rst_function_test(dut):
    dut.rst.value = 1

    await n_cycles_clock(dut, 10)

    dut.rst.value = 0


async def generate_round_keys(dut):
    print("generate_round_keys")
    dut.rst.value = 0
    i = 0
    while dut.end_key_generation.value.value == 0:
        i = i + 1
        await n_cycles_clock(dut, 1)

    # print(i)
    # await n_cycles_clock(dut,1)

    if dut.end_key_generation.value != 1:
        assert """Error generate_round_keys,wrong end_signal value = {0}, expected value is {1}""".format(
            hex(int(dut.end_key_generation.value.value)), 1
        )


async def enc_dec_test(dut, num_block, text, IV, key):
    print("enc_dec_test")
    dut.rq_data.value = 1
    await n_cycles_clock(dut, 1)
    dut.rq_data.value = 0

    i = 0
    dut.block_i.value = text
    dut.block_number.value = num_block

    present_SW = present_ctr.Present_CTR(key, IV)

    expected_value = present_SW.encryption_decryption(text, num_block)

    while dut.end_signal.value.value == 0:
        """
        print('//////////////////////////')
        print(int(dut.key_index_enc.value.value))
        print(int(dut.present_enc_impl.value.key_index.value))

        print(hex(int(dut.roundkey.value.value)))
        print(hex(int(dut.present_enc_impl.value.roundkey.value)))
        print(hex(int(present_SW.round_keys[int(dut.key_index_enc.value.value)])))

        print(hex(int(dut.present_enc_impl.value.block_i.value)))
        print(hex(int(dut.present_enc_impl.value.block_o.value)))


        print('//////////////////////////')
        """
        await n_cycles_clock(dut, 1)
        i = i + 1

    # print(i)

    await n_cycles_clock(dut, 100)
    print("*************************")
    print(hex(int(dut.block_o.value.value)))
    print(hex(text))
    print(hex(expected_value))
    print("*************************")
    if dut.block_o.value != expected_value:
        assert """Error enc_dec_test,wrong value = {0}, expected value is {1}""".format(
            hex(int(dut.block_o.value.value)), hex(expected_value)
        )


async def n_cycles_clock(dut, n):
    for i in range(0, n):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)


async def run_test(dut, index=0):

    n_blocks = 5

    key = random.getrandbits(KEY_LEN)
    IV = random.getrandbits(IV_LEN)
    print(hex(key))
    print(hex(IV))

    setup_function(dut, key, IV, 0, 0)
    await rst_function_test(dut)
    await generate_round_keys(dut)

    print(n_blocks)
    for j in range(0, n_blocks):
        print(j)
        plaintext = random.getrandbits(BLOCK_LEN)
        await enc_dec_test(dut, j, plaintext, IV, key)


n = 10
factory = TestFactory(run_test)

# array de 10 int aleatorios entre 0 y 31
factory.add_option("index", range(0, n))
factory.generate_tests()
