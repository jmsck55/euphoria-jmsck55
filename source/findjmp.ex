-- (c) Copyright - See License.txt
--****
-- == findjmp.ex: Find jumptab from be_execute.obj
--
-- This program disassembles be_execute.obj and parses the assembler code to determine
-- what jumptab should have been set to. Algorithm Thanks to Jim Brown

include std/convert.e
include std/filesys.e
include std/os.e
include std/types.e

export function write_jmp_file(sequence obj, sequence outfile, integer interactive = 1)
	if not file_exists(obj) then
		if interactive then
			printf(2, "%s does not exist\n", { obj })
		end if

		return 0
	end if

	object void = delete_file("be_execute.asm")
	sequence cmd = sprintf("wdis %s > be_execute.asm", { obj })

	system(cmd, 0)

	if not file_exists("be_execute.asm") then
		if interactive then
			printf(2, "resulting be_execute.asm was not created\n", {})
		end if

		return 0
	end if

	integer asm = open("be_execute.asm","r")
	object line
	atom exec_addr = 0, jmp_addr = 0

	line = ""

	while sequence(line) and not
		match( " Execute_:", line ) do
		line = gets(asm)
	end while

	if sequence(line) and length(line) > 7 then
		exec_addr = hex_text(line[1..8] )
	end if

	line = gets(asm)

	while sequence(line) and not match( " DD\t", line ) do
		line = gets(asm)
	end while

	jmp_addr = hex_text(line[1..8])
	close(asm)

	void = delete_file("be_execute.asm")

	if exec_addr and jmp_addr then
		integer fh = open(outfile, "w")
		if fh = -1 then
			if interactive then
				printf(2, "Cannot open \"%s\" for writing\n", {outfile})
			end if

			return 0
		end if

		-- create .c file for jumptab address
		printf(fh,"/* Important! The offset below is based on the object code WATCOM\n" &
			 " * generates for be_execute.c. It is the address of the internal jump table\n" &
			 " * generated by the compiler for the main switch statement in be_execute.c.\n" &
			 " * This file is automatically generated by findjmp.ex.\n" & 
			 " */\n" &
			"void Execute(int *);\nint ** jumptab = ((int**)Execute)+%d;\n", 
	     		{jmp_addr - exec_addr }/4 )
		close(fh)
	else
		return 0
	end if

	return 1
end function

-- Only run automatically if findjmp.ex was executed directly, i.e. not included
-- from another eui program

sequence cmds = command_line()
if match("findjmp.ex", cmds[2]) then
	sequence
		obj = "be_execute.obj",
		outfile = "be_magic.c"

	if length(cmds) > 2 then
		outfile = cmds[3]
	end if

	if length(cmds) > 3 then
		obj = cmds[4]
	end if

	if not write_jmp_file(obj, outfile) then
		abort(1)
	end if
end if