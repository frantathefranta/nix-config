local vlan20 = newNMG()
vlan20:addMask("10.0.20.0/24")
vlan20:addMask("2600:1702:6630:3fe1::/64")

local vlan50 = newNMG()
vlan50:addMask("10.0.50.0/24")
vlan50:addMask("2600:1702:6630:3fe2::/64")

local names = {
  ["neon.infra.franta.us."] = true,
  ["hass.infra.franta.us."] = true,
}

local addresses = {
  [20] = { [pdns.A] = "10.0.20.92", [pdns.AAAA] = "2600:1702:6630:3fe1:10:0:20:92" },
  [50] = { [pdns.A] = "10.0.50.92", [pdns.AAAA] = "2600:1702:6630:3fe2:10:0:50:92" },
}

-- Select the packet-cache partition before lookup, not just when answering.
function gettag(remote)
  if vlan20:match(remote) then return 20 end
  if vlan50:match(remote) then return 50 end
  return 0
end

function preresolve(dq)
  if not names[dq.qname:toString():lower()] then return false end

  local subnet = addresses[dq.tag]
  local address = subnet and subnet[dq.qtype]
  if not address then return false end

  dq:addAnswer(dq.qtype, address, 60)
  return true
end
