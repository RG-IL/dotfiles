-- Switch the default output to a Bluetooth sink as soon as it appears.
--
-- WirePlumber's default policy never promotes a newly connected device:
-- the currently configured default sink gets a +30000 priority bonus and
-- previously selected sinks get +20000, so a fresh Bluetooth node always
-- loses while another output exists. This hook closes that gap by making
-- any bluez_output sink the configured default the moment it shows up.

metadata_om = ObjectManager {
  Interest {
    type = "metadata",
    Constraint { "metadata.name", "=", "default" },
  }
}

node_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "matches", "Audio/Sink", type = "pw-global" },
    Constraint { "node.name", "matches", "bluez_output.*" },
  }
}

function setDefault (node)
  local metadata = metadata_om:lookup {}
  if not metadata then
    return
  end
  local name = node.properties["node.name"]
  Log.info ("switching default sink to " .. name)
  metadata:set (0, "default.configured.audio.sink", "Spa:String:JSON",
      Json.Object { ["name"] = name }:to_string ())
end

node_om:connect ("object-added", function (_, node)
  -- let the node finish binding before pointing the default at it
  Core.timeout_add (500, function ()
    setDefault (node)
  end)
end)

node_om:activate ()
metadata_om:activate ()