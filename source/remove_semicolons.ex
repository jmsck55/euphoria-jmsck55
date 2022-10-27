-- Copyright (c) 2022 James Cook
-- remove_semicolons.ex
--
-- Removes extra semicolons, making code more secure.
-- Warning: execution happens immediately in the current directory.

/* Semicolons in these and others have to be removed: */
/* {"Ref", "Refn", "DeRefDS", "DeRefDSi", "DeRef",
	"DeRefi", "DeRefDSx", "DeRefSP", "DeRefx"} */

include std/filesys.e
include std/io.e
include std/search.e
include std/types.e

/* Semicolons in these and others have to be removed:
   See also: include\euphoria.h, source\execute.h
*/
constant No_Semicolons = {"Ref", "Refn", "DeRefDS", "DeRefDSi", "DeRef",
	"DeRefi", "DeRefDSx", "DeRefSP", "DeRefx"}

constant file_exts = {"c","h","cpp","hpp"}

function look_at(sequence path_name, sequence item)
	sequence file, name, tmp
	integer found, pos, lisp, count
	if find('d', item[D_ATTRIBUTES]) then
		return 0 -- Ignore directories
	end if
	if not find(fileext(item[D_NAME]), file_exts) then
		return 0 -- ignore non-C/C++ files
	end if
	
	puts(STDOUT, item[D_NAME] & "...")
	
	file = read_file(item[D_NAME])
	
	-- remove semicolons:
	
	count = 0
	found = 0
	while 1 do
		found = find(';', file, found + 1)
		if found = 0 then
			exit
		end if
		pos = found - 1
		while t_space(file[pos]) do
			pos -= 1
		end while
		lisp = 0
		while pos >= 1 do
			if file[pos] = ')' then
				lisp += 1
			elsif file[pos] = '(' then
				lisp -= 1
			end if
			pos -= 1
			if lisp = 0 then
				exit
			end if
		end while
		while t_space(file[pos]) do
			pos -= 1
		end while
		for i = 1 to length(No_Semicolons) do
			name = No_Semicolons[i]
			if pos > length(name) then
				tmp = file[pos - length(name)..pos]
				if not t_identifier(tmp) then
					if equal(tmp[2..$], name) then
						-- great!, let's remove the extra semicolon:
						file[found] = ' ' -- replace semicolon with space character.
						-- file = file[1..found - 1] & file[found + 1..$]
						found -= 1
						count += 1
						exit
					end if
				end if
			end if
		end for
	end while
	
	if count then
		if write_file(item[D_NAME], file) = -1 then
			puts(STDOUT, "unable to write to file.\n")
			return 1
		end if
		printf(STDOUT, "success, %d semicolons removed.\n", {count})
	else
		puts(STDOUT, "unchanged.\n")
	end if
	return 0 -- keep going
end function

-- main():

puts(1, "Replace all semicolons with space character after these macros:\n")
for i = 1 to length(No_Semicolons) do
	printf(1, "%s()", {No_Semicolons[i]})
	if i != length(No_Semicolons) then
		puts(1, ", ")
	else
		puts(1, "\n")
	end if
end for

puts(1, "in these files:\n")
for i = 1 to length(file_exts) do
	printf(1, "*.%s\n", {file_exts[i]})
end for

puts(1, "in your current directory:\n")
printf(1, "%s\n", {curdir()})

puts(1, "Proceed? [yn]")
integer ch = getc(0)
if ch != 'y' and ch != 'Y' then
	puts(1, "Aborted, no files changed.\n")
	abort(0)
end if

if walk_dir(".", routine_id("look_at")) then
	puts(STDOUT, "An error has occurred in remove_semicolons.ex\n")
	abort(1/0)
end if

