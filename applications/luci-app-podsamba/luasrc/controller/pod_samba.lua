module("luci.controller.pod_samba",package.seeall)
function index()
  if not nixio.fs.access("/etc/config/pod_samba") then return end
  entry({"admin","services","pod_samba"},cbi("pod_samba"),_("Pod Samba")).leaf=true
end
