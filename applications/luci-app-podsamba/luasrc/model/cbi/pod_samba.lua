--[[
LuCI - Lua Configuration Interface
Copyright 2019 lisaac <lisaac.cn@gmail.com>
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
	http://www.apache.org/licenses/LICENSE-2.0
$Id$
]]--

local docker = require "luci.model.docker"
local dk = docker.new()
local pod_name = luci.model.uci:get("pod_samba", "pod", "pod_name")
local image_name = luci.model.uci:get("pod_samba", "pod", "image_name")
local pod_smb_config = luci.model.uci:get("pod_samba", "pod", "pod_smb_config")
local pod_smb_passwd = luci.model.uci:get("pod_samba", "pod", "pod_smb_passwd")
local tmp_conf_dir = "/tmp/conf.d/"..pod_name.."/"
local pod_alive = false

local m

local res = dk.containers:get_archive({ name = pod_name, query = { path = pod_smb_passwd }})
if res and res.code == 200 then
  pod_alive = true
  nixio.fs.mkdirr(tmp_conf_dir)
  nixio.fs.writefile(tmp_conf_dir.."pod_conf.tar", table.concat(res.body))
  luci.util.exec("tar xf "..tmp_conf_dir.."pod_conf.tar -C "..tmp_conf_dir)
  m = Map("pod_samba", translate("POD Samba"), "<a href='"..luci.dispatcher.build_url("admin/docker/container/"..pod_name).."' >Pod: "..pod_name .. "</a>")
else
  nixio.fs.mkdirr(tmp_conf_dir)
  nixio.fs.writefile(tmp_conf_dir.."/smbpasswd", "")
  local res = dk.containers:inspect({ name = pod_name})
  if res == 200 then
    m = Map("pod_samba", translate("POD Samba"), "<a href='"..luci.dispatcher.build_url("admin/docker/container/"..pod_name).."' >".. translate("the Pod(container)「".. pod_name.. "」can NOT connect, please start it first!") .. "</a>")
  else
    local cmd = "DOCKERCLI -d --name ".. pod_name ..
            " --restart unless-stopped "..
            "-e TZ=Asia/Shanghai "..
            "--network host "..
            "-v /media:/media:rslave,ro "..image_name
    m = Map("pod_samba", translate("POD Samba"), "<a href='"..luci.dispatcher.build_url("admin/docker/newcontainer/".. luci.util.urlencode(cmd)).."' >".. translate("There is no Pod(container) named 「".. pod_name.. "」, please create it first!") .. "</a>")
  end
  -- since there no pod, so disable apply & save button
  m.formvalue = function(self, x, ...)
    if x == "cbi.skip" then
      return true
    else
      m.formvalue(self, ...)
    end
  end
end

local s = m:section(NamedSection, "samba")

s:tab("general",  translate("General Settings"))
s:tab("template", translate("Edit Template"))

-- for general setting
s:taboption("general", Value, "name", translate("Hostname"))
s:taboption("general", Value, "description", translate("Description"))
s:taboption("general", Value, "workgroup", translate("Workgroup"))
-- s:taboption("general",Value, "hosts_allow",translate("Allow hosts to visit samba")).datatype="ip4addr"
-- s:taboption("general",Value, "hosts_deny",translate("Deny hosts to visit samba")).datatype="ip4addr"

-- for edit template
local tmpl = s:taboption("template", Value, "_tmpl", translate("Edit the template that is used for generating the samba configuration."), translate("This is the content of the file '/etc/config/template/pod.smb.conf.template' from which your samba configuration will be generated. Values enclosed by pipe symbols ('|') should not be changed. They get their values from the 'General Settings' tab."))
tmpl.template = "cbi/tvalue"
tmpl.rows = 30

-- functions for template editing
function tmpl.cfgvalue(self, section)
  return nixio.fs.readfile("/etc/config/template/pod.smb.conf.template")
end

function tmpl.write(self, section, value)
  value = value:gsub("\r\n?", "\n")
  nixio.fs.writefile("/etc/config/template/pod.smb.conf.template", value)
end

local SYSROOT = os.getenv("LUCI_SYSROOT")
if SYSROOT then
  local reset_temp = s:taboption("template", Button, "_reset", translate("Reset template"))
  reset_temp.inputstyle = "remove"
  reset_temp.write = function(self, section, value)
    nixio.fs.copy(SYSROOT .. "/etc/config/template/pod.smb.conf.template", "/etc/config/template/pod.smb.conf.template")
  end
end

-- for users setting
s = m:section(TypedSection, "sambauser", translate("Users Setting")
  , translate("Please add user for samba."))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"

local enabled = s:option(Flag, "enabled", translate("Enable"))
enabled.default = "yes"
enabled.rmempty = false
enabled.enabled = "yes"
enabled.disabled = "no"

local username = s:option(Value, "username", translate("User Name"))
username.rmempty = false
function username.validate(slef, value)
  if (value ~= "" and value ~= nil) then
    return value
  end
end

local passwd=s:option(Value, "passwd", translate("Password"))
passwd.rmempty = false
passwd.password = true
function passwd.validate(slef, value)
  if (value ~= "" and value ~= nil) then
    return value
  end
end

local uid = s:option(Value, "uid", translate("UID"))
uid.rmempty = false
function uid.validate(slef, value)
  if tonumber(value) then
    return value
  end
end

local last_mod = s:option(DummyValue, "last_mod", translate("Last Modify"))

-- the "section" argument is the identifier of the row (uci section) we operate on
function last_mod.cfgvalue(self, section)
  local username_value = m:get(section, 'username')
  -- alternatively:
  -- local username = username:cfgvalue(section)
  if username_value == nil or username_value == '' then return '?' end
  last_mod_val = luci.util.exec("cat "..tmp_conf_dir.."/smbpasswd | awk -F':' '{if ($1 == \"'"..username_value.."'\") print $6}'| awk -F'-' '{print $2}'")
  if last_mod_val == nil or last_mod_val == '' then return '?' end
  last_mod_val = os.date("%Y-%m-%d %H:%M:%S", tonumber(last_mod_val, 16))
  return last_mod_val or '?'
end

-- for share setting
s = m:section(TypedSection, "sambashare", translate("Shared Directories"), translate("Please add directories to share. Each directory refers to a folder on a mounted device."))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"

name=s:option(Value, "name", translate("Name"))
name.rmempty = true
pth = s:option(Value, "path", translate("Path"))
if nixio.fs.access("/etc/config/fstab") then
  pth.titleref = luci.dispatcher.build_url("admin", "system", "fstab")
end

users=s:option(MultiValue, "users", translate("Allowed users"))
users.rmempty = true
-- users.widget = "select"
m.uci:foreach(pod_name, "sambauser",
  function(i)
    users:value(i.username, i.username)
  end)

local ro = s:option(Flag, "read_only", translate("Read-only"))
ro.rmempty = false
ro.enabled = "yes"
ro.disabled = "no"

local br = s:option(Flag, "browseable", translate("Browseable"))
br.rmempty = false
br.default = "yes"
br.enabled = "yes"
br.disabled = "no"

local go = s:option(Flag, "guest_ok", translate("Allow guests"))
go.rmempty = false
go.enabled = "yes"
go.disabled = "no"

local cm = s:option(Value, "create_mask", translate("Create mask"), translate("Mask for new files"))
cm.rmempty = true

local dm = s:option(Value, "dir_mask", translate("Directory mask"), translate("Mask for new directories"))
dm.rmempty = true

return m
