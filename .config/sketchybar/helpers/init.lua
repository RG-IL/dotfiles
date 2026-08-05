-- Add the sketchybar module to the package cpath
package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"

os.execute("(cd helpers && make)")

-- Read a small status file synchronously. Avoids forking a shell + /bin/cat
-- per update — each subprocess spawn triggers syspolicyd/tccd validation on
-- macOS, which is the dominant per-update cost in the file-backed widgets.
function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end
