module("luci.controller.pod_app.samba",package.seeall)
function index()
entry({"admin","services","pod_samba"},cbi("pod_app/samba"),_("Samba in container")).leaf=true
end
