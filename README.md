# Samba docker container
Samba docker container, 作为 [luci-in-docker](https://github.com/lisaac/luci-in-docker) 插件, 通过 luci 进行配置

## Depends / 依赖
- [luci-lib-docker](https://github.com/lisaac/luci-lib-docker)
- [luci-app-dockerman](https://github.com/lisaac/luci-app-dockerman)

## Quick start / 快速开始

### 部署 [luci-in-docker](https://github.com/lisaac/luci-in-docker)
```
docker run -d \
  --name luci \
  --restart unless-stopped \
  --privileged \
  -p 80:80 \
  -e TZ=Asia/Shanghai \
  -v $HOME/pods/luci:/external:rslave \
  -v /media:/media:rshared \
  -v /dev:/dev:rslave \
  -v /:/host:ro,rshared \
  -v /usr/bin/docker:/usr/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --tmpfs /tmp:exec \
  --tmpfs /run \
  lisaac/luci
```

### 安装插件
```
# 添加插件依赖
git clone https://github.com/lisaac/luci-lib-docker $HOME/pods/luci/plugin/luci-lib-docker
git clone https://github.com/lisaac/luci-app-dockerman $HOME/pods/luci/plugin/luci-app-dockerman
# 安装插件
git clone http://github.com/lisaac/luci-plugin-samba $HOME/pods/luci/plugin/luci-lib-docker

# 重启luci容器
docker restart luci
```

### 使用
部署完成后, 浏览器访问宿主机 ip, 即可得到 `luci` 页面, 通过 `Services -> Samba in container` 配置
首次进入会跳转至创建容器页面, 请按自己需求配置, 创建完成后,再次进入`Services -> Samba in container`即可配置
配置类似`openwrt`, 加入自定义用户支持

## 说明
- 容器名为`luci_plugin_samba`, 请勿修改
- 容器默认通过`host`网络进行部署, 如果想要修改, 请在创建时自行修改内容, 若改为`bridge`模式, 确保暴露`137/138/139/445`端口
- 创建容器时默认只挂载`/media`到容器内部, 需要其他目录, 请在创建时自行添加
- 配置文件保存在宿主机`$HOME/pods/luci/conf.d/config/luci_plugin_samba`中

## 谢致
- [dperson/samba](https://github.com/dperson/samba)

Enjoy