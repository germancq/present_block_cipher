#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : present_test.py
# Author            : German C.Quiveu <germancq@dte.us.es>
# Date              : 17.06.2026
# Last Modified Date: 17.06.2026
# Last Modified By  : German C.Quiveu <germancq@dte.us.es>

import importlib
import os
import random
import sys
import time

import numpy as np
import present

import cocotb
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.result import TestFailure
from cocotb.triggers import FallingEdge, RisingEdge, Timer

home = os.getenv("HOME")

KEY_LEN = 80
BLOCK_LEN = 64
CLK_PERIOD = 20  # 50 MHz
SIGNATURE = 0xAABBCCDD

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


def setup_function(dut, key, plaintext):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())
    dut.rst.value = 0
    dut.key.value = key
    dut.block_i.value = plaintext
    dut.enc_dec.value = 0


async def rst_function_test(dut):
    dut.rst.value = 1

    await n_cycles_clock(dut, 10)

    dut.rst.value = 0


async def generate_round_keys(dut):
    dut.rst.value = 0
    i = 0
    while dut.end_key_generation.value == 0:
        i = i + 1
        await n_cycles_clock(dut, 1)

    print(i)
    # await n_cycles_clock(dut,1)

    if dut.end_key_generation != 1:
        raise TestFailure(
            """Error generate_round_keys,wrong end_signal value = {0}, expected value is {1}""".format(
                hex(int(dut.end_key_generation.value)), 1
            )
        )


async def enc_test(dut, expected_enc_value):

    i = 0
    dut.enc_dec.value = 0
    while dut.end_signal.value == 0:
        """
        print("//////////////////////////")
        print(int(dut.key_index.value))
        print(int(dut.present_enc_impl.key_index.value))
        print(hex(int(dut.roundkey.value)))
        print(hex(int(dut.present_enc_impl.roundkey.value)))
        print(hex(int(dut.present_enc_impl.block_i.value)))
        print(hex(int(dut.present_enc_impl.block_o.value)))

        print("//////////////////////////")
        """
        await n_cycles_clock(dut, 1)
        i = i + 1

    print(i)

    await n_cycles_clock(dut, 100)

    print(hex(int(dut.block_o.value)))
    print(hex(int(expected_enc_value)))
    if dut.block_o != expected_enc_value:
        raise TestFailure(
            """Error enc_test,wrong value = {0}, expected value is {1}""".format(
                hex(int(dut.block_o.value)), hex(expected_enc_value)
            )
        )


async def dec_test(dut, expected_dec_value):

    i = 0
    dut.enc_dec.value = 1
    print(int(dut.present_dec_impl.key_index.value))
    while dut.end_signal.value == 0:
        """
        print("***********************")
        print(int(dut.key_index.value))
        print(int(dut.present_dec_impl.key_index.value))
        print(hex(int(dut.roundkey.value)))
        print(hex(int(dut.present_dec_impl.roundkey.value)))
        print(hex(int(dut.present_dec_impl.block_i.value)))
        print(hex(int(dut.present_dec_impl.block_o.value)))

        print("*************************")
        """
        await n_cycles_clock(dut, 1)

    await n_cycles_clock(dut, 100)

    print(hex(int(dut.block_o.value)))
    print(hex(int(expected_dec_value)))
    if dut.block_o != expected_dec_value:
        raise TestFailure(
            """Error dec_test,wrong value = {0}, expected value is {1}""".format(
                hex(int(dut.block_o.value)), hex(expected_dec_value)
            )
        )


async def n_cycles_clock(dut, n):
    for i in range(0, n):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)


async def run_test(dut, index=0):

    # key = 0x0
    # text = 0x0
    key = random.getrandbits(KEY_LEN)
    text = random.getrandbits(BLOCK_LEN)
    present_SW = present.Present(key)
    expected_value_enc = present_SW.encrypt(text)
    expected_value_dec = present_SW.decrypt(text)

    setup_function(dut, key, text)

    await rst_function_test(dut)
    await generate_round_keys(dut)
    await dec_test(dut, expected_value_dec)
    await enc_test(dut, expected_value_enc)


n = 10
factory = TestFactory(run_test)

# array de 10 int aleatorios entre 0 y 31
factory.add_option("index", range(0, n))
factory.generate_tests()
