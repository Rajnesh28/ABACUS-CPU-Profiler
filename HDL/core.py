# Modified CVA5 core.py to instantiate ABACUS IP over wishbone, and wire nets from the core to ABACUS
# This file is part of LiteX.
#
# Copyright (c) 2022 Eric Matthews <eric.charles.matthews@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause

import os

from migen import *

from litex import get_data_mod

from litex.gen import *

from litex.soc.interconnect import wishbone, axi
from litex.soc.interconnect.csr import *
from litex.soc.cores.cpu import CPU, CPU_GCC_TRIPLE_RISCV32
from litex.soc.integration.soc import SoCRegion

# Variants -----------------------------------------------------------------------------------------

CPU_VARIANTS = ["minimal", "standard"]

# GCC Flags ----------------------------------------------------------------------------------------

GCC_FLAGS = {
    #                        /------------ Base ISA
    #                        |    /------- Hardware Multiply + Divide
    #                        |    |/----- Atomics
    #                        |    ||/---- Compressed ISA
    #                        |    |||/--- Single-Precision Floating-Point
    #                        |    ||||/-- Double-Precision Floating-Point
    #                        i    macfd
    "minimal"  : "-march=rv32i2p0   -mabi=ilp32 ",
    "standard" : "-march=rv32i2p0_m -mabi=ilp32 ",
}

# CVA5 ----------------------------------------------------------------------------------------------

class CVA5(CPU):
    category             = "softcore"
    family               = "riscv"
    name                 = "cva5"
    variants             = CPU_VARIANTS
    data_width           = 32
    endianness           = "little"
    gcc_triple           = CPU_GCC_TRIPLE_RISCV32
    linker_output_format = "elf32-littleriscv"
    nop                  = "nop"
    io_regions           = {0x80000000: 0x80000000} # origin, length
    plic_base            = 0xf800_0000
    clint_base           = 0xf001_0000
    test_base            = 0xf003_0000

    # Memory Mapping.
    @property
    def mem_map(self):
        return {
            "rom":            0x0000_0000,
            "sram":           0x1000_0000,
            "main_ram":       0x4000_0000,
            "csr":            0xf000_0000,
        }
    
    # GCC Flags.
    @property
    def gcc_flags(self):
        flags = GCC_FLAGS[self.variant]
        flags += "-D__riscv_plic__"
        return flags

    def __init__(self, platform, variant="standard"):
        self.platform     = platform
        self.variant      = variant
        self.human_name   = f"CVA5-{variant.upper()}"
        self.reset        = Signal()
        self.interrupt    = Signal(2)
        self.periph_buses = [] # Peripheral buses (Connected to main SoC's bus).
        self.memory_buses = [] # Memory buses (Connected directly to LiteDRAM).

        # CPU Instance.
        self.cpu_params = dict(
            # Configuration.           
            p_RESET_VEC      = 0,
            p_NON_CACHABLE_L = 0x80000000, # FIXME: Use io_regions.
            p_NON_CACHABLE_H = 0xFFFFFFFF, # FIXME: Use io_regions.
            # Clk/Rst.
            i_clk = ClockSignal("sys"),
            i_rst = ResetSignal("sys"),
        )
       
        # Standard variant includes instruction and data caches, multiply and divide support
        # along with the branch predictor. It uses a shared wishbone interface.
        self.idbus = idbus = wishbone.Interface(data_width=32, address_width=32, addressing="word")
        self.periph_buses.append(idbus)
        self.cpu_params.update(
            o_idbus_adr   = idbus.adr,
            o_idbus_dat_w = idbus.dat_w,
            o_idbus_sel   = idbus.sel,
            o_idbus_cyc   = idbus.cyc,
            o_idbus_stb   = idbus.stb,
            o_idbus_we    = idbus.we,
            o_idbus_cti   = idbus.cti,
            o_idbus_bte   = idbus.bte,
            i_idbus_dat_r = idbus.dat_r,
            i_idbus_ack   = idbus.ack,
            i_idbus_err   = idbus.err,
        )
        self.add_sources(platform)

    def set_reset_address(self, reset_address):
        assert not hasattr(self, "reset_address")
        self.reset_address = reset_address
        self.cpu_params.update(p_RESET_VEC=reset_address)

    @staticmethod
    def add_sources(platform):
        cva5_path = get_data_mod("cpu", "cva5").data_location
        with open(os.path.join(cva5_path, "tools/compile_order"), "r") as f:
            for line in f:
                if line.strip() != '':
                    platform.add_source(os.path.join(cva5_path, line.strip()))
        platform.add_source(os.path.join(cva5_path, "examples/litex/litex_wrapper.sv"))
        platform.add_source(os.path.join(cva5_path, "/localhome/rajneshj/USRA/ABACUS/HDL/abacus_top.sv"))
        platform.add_source(os.path.join(cva5_path, "/localhome/rajneshj/USRA/ABACUS/HDL/profiling_units/instruction_profiler.sv"))
        platform.add_source(os.path.join(cva5_path, "/localhome/rajneshj/USRA/ABACUS/HDL/profiling_units/cache_profiler.sv"))
        platform.add_source(os.path.join(cva5_path, "/localhome/rajneshj/USRA/ABACUS/HDL/profiling_units/stall_unit.sv"))

    def do_finalize(self):
        assert hasattr(self, "reset_address")
        self.specials += Instance("litex_wrapper", **self.cpu_params)

    def add_soc_components(self, soc):
        soc.csr.add("sdram", n=1)
        soc.csr.add("uart", n=2)
        soc.csr.add("timer0", n=3)
        soc.csr.add("supervisor", n=4)

        # PLIC
        seip = Signal()
        meip = Signal()
        eip = Signal(2)
        es = Signal(2, reset=0)

        self.plicbus = plicbus = wishbone.Interface(data_width=32, address_width=32, addressing="word")
        self.specials += Instance("plic_wrapper",
            p_NUM_SOURCES = 2,
            p_NUM_TARGETS = 2,
            p_PRIORITY_W = 8,
            p_REG_STAGE = 1,
            p_AXI = 0,
            i_clk = ClockSignal("sys"),
            i_rst = ResetSignal("sys"),
            i_wb_cyc = plicbus.cyc,
            i_wb_stb = plicbus.stb,
            i_wb_we = plicbus.we,
            i_wb_adr = plicbus.adr,
            i_wb_dat_i = plicbus.dat_w,
            o_wb_dat_o = plicbus.dat_r,
            o_wb_ack = plicbus.ack,
            i_irq_srcs = self.interrupt,
            i_edge_sensitive = es,
            o_eip = eip,
            i_axi_awvalid = Open(),
            i_axi_awaddr = Open(),
            i_axi_wvalid = Open(),
            i_axi_wdata = Open(),
            i_axi_bready = Open(),
            i_axi_arvalid = Open(),
            i_axi_araddr = Open(),
            i_axi_rready = Open(),
            o_axi_awready = Open(),
            o_axi_wready = Open(),
            o_axi_bvalid = Open(),
            o_axi_arready = Open(),
            o_axi_rvalid = Open(),
            o_axi_rdata = Open()
        )
        self.comb += [
            meip.eq(eip[0]),
            seip.eq(eip[1])
        ]
        self.cpu_params.update(
            i_seip = seip,
            i_meip = meip
        )

        soc.bus.add_slave("plic", self.plicbus, region=SoCRegion(origin=self.plic_base, size=0x400_0000, cached=False))

        # CLINT
        mtime = Signal(64)
        msip = Signal()
        mtip = Signal()
        
        self.clintbus = clintbus = wishbone.Interface(data_width=32, address_width=32, addressing="word")
        self.specials += Instance("clint_wrapper",
            p_NUM_CORES = 1,
            p_AXI = 0,
            i_clk = ClockSignal("sys"),
            i_rst = ResetSignal("sys"),
            i_wb_cyc = clintbus.cyc,
            i_wb_stb = clintbus.stb,
            i_wb_we = clintbus.we,
            i_wb_adr = clintbus.adr,
            i_wb_dat_i = clintbus.dat_w,
            o_wb_dat_o = clintbus.dat_r,
            o_wb_ack = clintbus.ack,
            o_mtip = mtip,
            o_msip = msip,
            o_mtime  = mtime,
            i_axi_awvalid = Open(),
            i_axi_awaddr = Open(),
            i_axi_wvalid = Open(),
            i_axi_wdata = Open(),
            i_axi_bready = Open(),
            i_axi_arvalid = Open(),
            i_axi_araddr = Open(),
            i_axi_rready = Open(),
            o_axi_awready = Open(),
            o_axi_wready = Open(),
            o_axi_bvalid = Open(),
            o_axi_arready = Open(),
            o_axi_rvalid = Open(),
            o_axi_rdata = Open()
        )
        
        self.cpu_params.update(
            i_mtime = mtime,
            i_msip = msip,
            i_mtip = mtip
        )

        soc.bus.add_slave("clint", clintbus, region=SoCRegion(origin=self.clint_base, size=0x1_0000, cached=False))

        # Instruction Profiling Unit
        abacus_instruction = Signal(32)
        abacus_instruction_issued = Signal()

        # Cache Profiling Unit
        abacus_icache_request = Signal()
        abacus_icache_miss = Signal()
        abacus_icache_line_fill_in_progress = Signal()
        abacus_dcache_request = Signal()
        abacus_dcache_hit = Signal()
        abacus_dcache_line_fill_in_progress = Signal()

        # Stall Unit Profiling Unit
        abacus_branch_misprediction = Signal()
        abacus_ras_misprediction = Signal()
        abacus_issue_no_instruction_stat = Signal()
        abacus_issue_no_id_stat = Signal()
        abacus_issue_flush_stat = Signal()
        abacus_issue_unit_busy_stat = Signal()
        abacus_issue_operands_not_ready_stat = Signal()
        abacus_issue_hold_stat = Signal()
        abacus_issue_multi_source_stat = Signal()

        self.cpu_params.update (
            o_abacus_instruction = abacus_instruction,
            o_abacus_instruction_issued = abacus_instruction_issued,

            o_abacus_icache_request = abacus_icache_request,
            o_abacus_dcache_request = abacus_dcache_request,
            o_abacus_icache_miss = abacus_icache_miss,
            o_abacus_dcache_hit = abacus_dcache_hit,

            o_abacus_icache_line_fill_in_progress = abacus_icache_line_fill_in_progress,
            o_abacus_dcache_line_fill_in_progress = abacus_dcache_line_fill_in_progress,

            o_abacus_branch_misprediction = abacus_branch_misprediction,
            o_abacus_ras_misprediction = abacus_ras_misprediction,
            o_abacus_issue_no_instruction_stat = abacus_issue_no_instruction_stat,
            o_abacus_issue_no_id_stat = abacus_issue_no_id_stat,
            o_abacus_issue_flush_stat = abacus_issue_flush_stat,
            o_abacus_unit_busy_stat = abacus_issue_unit_busy_stat,
            o_abacus_issue_operands_not_ready_stat = abacus_issue_operands_not_ready_stat,
            o_abacus_issue_hold_stat = abacus_issue_hold_stat,
            o_abacus_issue_multi_source_stat = abacus_issue_multi_source_stat,

        )
        self.testbus = testbus = wishbone.Interface(data_width=32, address_width=32, addressing="byte")
        self.specials += Instance("abacus_top",
            p_WITH_AXI         = 0x0, # Use Wishbone
            p_ABACUS_BASE_ADDR = 0xf0030000,
            p_INCLUDE_INSTRUCTION_PROFILER = 0x1,
            p_INCLUDE_CACHE_PROFILER = 0x1,
            p_INCLUDE_STALL_UNIT = 0x1,

            i_clk = ClockSignal("sys"),
            i_rst = ResetSignal("sys"),
            i_wb_cyc = testbus.cyc,
            i_wb_stb = testbus.stb,
            i_wb_we = testbus.we,
            i_wb_adr = testbus.adr,
            i_wb_dat_i = testbus.dat_w,
            o_wb_dat_o = testbus.dat_r,
            o_wb_ack = testbus.ack,

            i_abacus_instruction = abacus_instruction,
            i_abacus_instruction_issued = abacus_instruction_issued,
            i_abacus_icache_request = abacus_icache_request,
            i_abacus_icache_miss = abacus_icache_miss,
            i_abacus_icache_line_fill_in_progress = abacus_icache_line_fill_in_progress,
            i_abacus_dcache_request = abacus_dcache_request,
            i_abacus_dcache_hit = abacus_dcache_hit,
            i_abacus_dcache_line_fill_in_progress = abacus_dcache_line_fill_in_progress,
            i_abacus_branch_misprediction = abacus_branch_misprediction,
            i_abacus_ras_misprediction = abacus_ras_misprediction,
            i_abacus_issue_no_instruction_stat = abacus_issue_no_instruction_stat,
            i_abacus_issue_no_id_stat = abacus_issue_no_id_stat,
            i_abacus_issue_flush_stat = abacus_issue_flush_stat,
            i_abacus_issue_unit_busy_stat = abacus_issue_unit_busy_stat,
            i_abacus_issue_operands_not_ready_stat = abacus_issue_operands_not_ready_stat,
            i_abacus_issue_hold_stat = abacus_issue_hold_stat,
            i_abacus_issue_multi_source_stat = abacus_issue_multi_source_stat,
        
            i_S_AXI_AWVALID = Open(),
            i_S_AXI_AWADDR = Open(),
            i_S_AXI_WVALID = Open(),
            i_S_AXI_WDATA = Open(),
            i_S_AXI_BREADY = Open(),
            i_S_AXI_ARVALID = Open(),
            i_S_AXI_ARADDR = Open(),
            i_S_AXI_RREADY = Open(),
            o_S_AXI_AWREADY = Open(),
            o_S_AXI_WREADY = Open(),
            o_S_AXI_BVALID = Open(),
            o_S_AXI_ARREADY = Open(),
            o_S_AXI_RVALID = Open(),
            o_S_AXI_RDATA = Open()

            )
        soc.bus.add_slave("test", testbus, region=SoCRegion(origin=self.test_base, size=0x1_0000, cached=False))

