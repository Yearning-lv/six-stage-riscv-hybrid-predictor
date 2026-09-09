import argparse
import re
from pathlib import Path

MASK32 = 0xFFFFFFFF


def u32(value):
    return value & MASK32


def s32(value):
    value = u32(value)
    return value if value < 0x80000000 else value - 0x100000000


def sign_extend(value, width):
    sign = 1 << (width - 1)
    value &= (1 << width) - 1
    return value - (1 << width) if value & sign else value


def bits(value, high, low):
    return (value >> low) & ((1 << (high - low + 1)) - 1)


def load_hex(path):
    words = {}
    for index, raw_line in enumerate(Path(path).read_text(encoding="utf-8").splitlines()):
        line = raw_line.split("#", 1)[0].strip()
        if not line:
            continue
        token = line.split()[0]
        if token.startswith("@"):
            index = int(token[1:], 16)
            continue
        words[index * 4] = int(token, 16) & MASK32
        index += 1
    return words


class RV32IReference:
    def __init__(self, program):
        self.program = program
        self.regs = [0] * 32
        self.memory = bytearray(1024)
        self.pc = 0

    def load_bytes(self, address, size):
        address &= MASK32
        value = 0
        for offset in range(size):
            index = address + offset
            if index >= len(self.memory):
                raise RuntimeError(f"data load outside memory at 0x{address:08x}")
            value |= self.memory[index] << (8 * offset)
        return value

    def store_bytes(self, address, value, size):
        address &= MASK32
        value = u32(value)
        for offset in range(size):
            index = address + offset
            if index >= len(self.memory):
                raise RuntimeError(f"data store outside memory at 0x{address:08x}")
            self.memory[index] = (value >> (8 * offset)) & 0xFF

    def execute(self, instruction):
        pc = self.pc
        opcode = instruction & 0x7F
        funct3 = bits(instruction, 14, 12)
        funct7 = bits(instruction, 31, 25)
        rs1 = bits(instruction, 19, 15)
        rs2 = bits(instruction, 24, 20)
        rd = bits(instruction, 11, 7)
        first = self.regs[rs1]
        second = self.regs[rs2]
        next_pc = u32(pc + 4)
        write_enable = False
        write_data = 0

        def write(value):
            nonlocal write_enable, write_data
            write_enable = True
            write_data = u32(value)
            if rd != 0:
                self.regs[rd] = write_data

        if opcode == 0x33:
            if funct3 == 0x0:
                write(first - second if funct7 == 0x20 else first + second)
            elif funct3 == 0x1:
                write(first << (second & 0x1F))
            elif funct3 == 0x2:
                write(int(s32(first) < s32(second)))
            elif funct3 == 0x3:
                write(int(first < second))
            elif funct3 == 0x4:
                write(first ^ second)
            elif funct3 == 0x5:
                write(s32(first) >> (second & 0x1F) if funct7 == 0x20
                      else first >> (second & 0x1F))
            elif funct3 == 0x6:
                write(first | second)
            elif funct3 == 0x7:
                write(first & second)
            else:
                raise RuntimeError(f"unsupported R-type at 0x{pc:08x}")
        elif opcode == 0x13:
            immediate = sign_extend(bits(instruction, 31, 20), 12)
            if funct3 == 0x0:
                write(first + immediate)
            elif funct3 == 0x1 and funct7 == 0x00:
                write(first << bits(instruction, 24, 20))
            elif funct3 == 0x2:
                write(int(s32(first) < immediate))
            elif funct3 == 0x3:
                write(int(first < u32(immediate)))
            elif funct3 == 0x4:
                write(first ^ u32(immediate))
            elif funct3 == 0x5:
                shift = bits(instruction, 24, 20)
                write(s32(first) >> shift if funct7 == 0x20 else first >> shift)
            elif funct3 == 0x6:
                write(first | u32(immediate))
            elif funct3 == 0x7:
                write(first & u32(immediate))
            else:
                raise RuntimeError(f"unsupported I-type at 0x{pc:08x}")
        elif opcode == 0x03:
            immediate = sign_extend(bits(instruction, 31, 20), 12)
            address = u32(first + immediate)
            if funct3 == 0x0:
                write(sign_extend(self.load_bytes(address, 1), 8))
            elif funct3 == 0x1:
                write(sign_extend(self.load_bytes(address, 2), 16))
            elif funct3 == 0x2:
                write(self.load_bytes(address, 4))
            elif funct3 == 0x4:
                write(self.load_bytes(address, 1))
            elif funct3 == 0x5:
                write(self.load_bytes(address, 2))
            else:
                raise RuntimeError(f"unsupported load at 0x{pc:08x}")
        elif opcode == 0x23:
            immediate = sign_extend(
                (bits(instruction, 31, 25) << 5) | bits(instruction, 11, 7), 12
            )
            address = u32(first + immediate)
            if funct3 == 0x0:
                self.store_bytes(address, second, 1)
            elif funct3 == 0x1:
                self.store_bytes(address, second, 2)
            elif funct3 == 0x2:
                self.store_bytes(address, second, 4)
            else:
                raise RuntimeError(f"unsupported store at 0x{pc:08x}")
        elif opcode == 0x63:
            immediate = sign_extend(
                (bits(instruction, 31, 31) << 12)
                | (bits(instruction, 7, 7) << 11)
                | (bits(instruction, 30, 25) << 5)
                | (bits(instruction, 11, 8) << 1),
                13,
            )
            taken = (
                (funct3 == 0x0 and first == second)
                or (funct3 == 0x1 and first != second)
                or (funct3 == 0x4 and s32(first) < s32(second))
                or (funct3 == 0x5 and s32(first) >= s32(second))
                or (funct3 == 0x6 and first < second)
                or (funct3 == 0x7 and first >= second)
            )
            if taken:
                next_pc = u32(pc + immediate)
        elif opcode == 0x6F:
            immediate = sign_extend(
                (bits(instruction, 31, 31) << 20)
                | (bits(instruction, 19, 12) << 12)
                | (bits(instruction, 20, 20) << 11)
                | (bits(instruction, 30, 21) << 1),
                21,
            )
            write(pc + 4)
            next_pc = u32(pc + immediate)
        elif opcode == 0x67 and funct3 == 0x0:
            immediate = sign_extend(bits(instruction, 31, 20), 12)
            write(pc + 4)
            next_pc = u32(first + immediate) & 0xFFFFFFFE
        elif opcode == 0x37:
            write(instruction & 0xFFFFF000)
        elif opcode == 0x17:
            write(pc + (instruction & 0xFFFFF000))
        else:
            raise RuntimeError(f"unsupported instruction 0x{instruction:08x} at 0x{pc:08x}")

        self.regs[0] = 0
        self.pc = next_pc
        return (pc, instruction, rd, int(write_enable), write_data)

    def run(self, max_steps, done_reg=31, done_value=123):
        events = []
        for _ in range(max_steps):
            instruction = self.program.get(self.pc, 0x00000013)
            event = self.execute(instruction)
            if instruction not in (0, 0x00000013):
                events.append(event)
            if self.regs[done_reg] == u32(done_value):
                return events
        raise RuntimeError("reference model timeout")

    def run_steps(self, step_count):
        events = []
        instruction_steps = 0
        while len(events) < step_count:
            instruction_steps += 1
            if instruction_steps > step_count * 20:
                raise RuntimeError("reference model fixed-step timeout")
            instruction = self.program.get(self.pc, 0x00000013)
            event = self.execute(instruction)
            if instruction not in (0, 0x00000013):
                events.append(event)
        return events

    def memory_words(self):
        return {
            index: int.from_bytes(self.memory[index * 4:index * 4 + 4], "little")
            for index in range(256)
        }


def parse_trace(path):
    events = []
    memory = {}
    pattern = re.compile(
        r"^\s*(\d+)\s+([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+"
        r"(\d+)\s+(\d+)\s+([0-9a-fA-F]+)\s*$"
    )
    for line_number, line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), 1):
        if not line or line.startswith("#"):
            continue
        if line.startswith("MEM "):
            fields = line.split()
            if len(fields) != 3:
                raise RuntimeError(f"invalid memory line {line_number}: {line}")
            memory[int(fields[1])] = int(fields[2], 16)
            continue
        match = pattern.match(line)
        if not match:
            raise RuntimeError(f"invalid trace line {line_number}: {line}")
        events.append(
            (
                int(match.group(2), 16),
                int(match.group(3), 16),
                int(match.group(4)),
                int(match.group(5)),
                int(match.group(6), 16),
            )
        )
    return events, memory


def compare(expected, actual):
    if len(expected) != len(actual):
        return f"commit count mismatch: expected {len(expected)}, got {len(actual)}"

    for index, (exp, got) in enumerate(zip(expected, actual)):
        if exp[0] != got[0] or exp[1] != got[1]:
            return (
                f"commit {index} mismatch: "
                f"expected pc=0x{exp[0]:08x} instr=0x{exp[1]:08x}, "
                f"got pc=0x{got[0]:08x} instr=0x{got[1]:08x}"
            )
        if exp[3] != got[3]:
            return f"commit {index} write-enable mismatch at pc=0x{exp[0]:08x}"
        if exp[3] and (exp[2] != got[2] or exp[4] != got[4]):
            return (
                f"commit {index} writeback mismatch at pc=0x{exp[0]:08x}: "
                f"expected rd=x{exp[2]} data=0x{exp[4]:08x}, "
                f"got rd=x{got[2]} data=0x{got[4]:08x}"
            )
    return None


def compare_memory(expected, actual):
    for index in range(256):
        expected_value = expected.get(index, 0)
        actual_value = actual.get(index, 0)
        if expected_value != actual_value:
            return (
                f"memory mismatch at mem[{index}]: "
                f"expected 0x{expected_value:08x}, got 0x{actual_value:08x}"
            )
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hex", required=True)
    parser.add_argument("--trace", required=True)
    parser.add_argument("--max-steps", type=int, default=100000)
    parser.add_argument("--steps", type=int, default=0)
    args = parser.parse_args()

    try:
        program = load_hex(args.hex)
        reference = RV32IReference(program)
        expected = (reference.run_steps(args.steps)
                    if args.steps > 0 else reference.run(args.max_steps))
        actual, actual_memory = parse_trace(args.trace)
        error = compare(expected, actual)
        if error is None:
            error = compare_memory(reference.memory_words(), actual_memory)
    except (OSError, RuntimeError, ValueError) as exc:
        print(f"FAIL: {exc}")
        return 1

    if error:
        print(f"FAIL: {error}")
        return 1

    print(f"PASS: trace matches ({len(actual)} commits)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


