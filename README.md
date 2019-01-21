### 说明
代码来自于 https://github.com/gjmzj/kubeasz
在此基础上，增加了一些自定义的内容，
尽情折腾吧。


### 虚拟机配置
#### CentOS系统镜像下载
```
# 我测试用的是这个镜像, vagrant版本2.2.2
http://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1805_01.VirtualBox.box
```
#### Vagrantfile文件配置
```
ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure("2") do |config|
    (1..6).each do |i|
      config.vm.define "k8s#{i}" do |node|
        node.vm.box = "centos"
        node.ssh.insert_key = false
        node.vm.hostname = "k8s#{i}"
        node.vm.network "private_network", ip: "192.168.150.18#{i}"
        node.vm.provision "shell",
          inline: "echo hello from node #{i}"
        node.vm.provider "virtualbox" do |v|
          v.cpus = 2
          v.customize ["modifyvm", :id, "--name", "k8s#{i}", "--memory", "1024"]
        end
      end
    end
end
```
#### 配置虚拟机
```
# 设置root用户密码
passwd

# 允许密码认证
vi /etc/ssh/sshd_config
PasswordAuthentication yes
service sshd restart
```

### 安装说明
以下都是使用root用户操作的。

#### 安装依赖
```
yum install epel-release git ansible -y

yum update -y

git clone https://github.com/limengyu1990/k8s-cluster.git /tmp/k8s-cluster

rm -rf /etc/ansible/* && mv /tmp/k8s-cluster/* /etc/ansible/

# 验证ansible
ansible all -m ping
```

#### 配置集群参数
```
vi /etc/ansible/hosts
```

#### 配置免密码登陆
```
# 需要配置/etc/ansible/hosts文件中的[ssh-addkey]
# 这一步执行成功后才可以执行下面的步骤
chmod +x ssh-addkey.sh && ./ssh-addkey.sh
```

#### 导入k8s二进制文件 
```
# 下载地址: https://pan.baidu.com/s/1c4RFaA
tar zxvf k8s.1-10-12.tar.gz
mv bin/* /etc/ansible/bin
```

#### 安装集群
```
# 分步安装
# 失败的话，可以多试几次
ansible-playbook 01.prepare.yml
ansible-playbook 02.etcd.yml
ansible-playbook 03.docker.yml
ansible-playbook 04.kube-master.yml
ansible-playbook 05.kube-node.yml
ansible-playbook 06.network.yml
ansible-playbook 07.cluster-addon.yml

# 一步安装
#ansible-playbook 90.setup.yml
```

#### 验证安装
```
kubectl version
kubectl get componentstatus # 可以看到scheduler/controller-manager/etcd等组件 Healthy
kubectl cluster-info # 可以看到kubernetes master(apiserver)组件 running
kubectl get node # 可以看到单 node Ready状态
kubectl get pod --all-namespaces # 可以查看所有集群pod状态，默认已安装网络插件、coredns、metrics-server等
kubectl get svc --all-namespaces # 可以查看所有集群服务状态
```

#### 清理集群
```
ansible-playbook 99.clean.yml
# 如果出现清理失败，类似报错：... Device or resource busy: '/var/run/docker/netns/xxxxxxxxxx'，需要手动umount该目录后清理
umount /var/run/docker/netns/xxxxxxxxxx
rm -rf /var/run/docker/netns/xxxxxxxxxx
```

### 登陆Dashboard
访问dashboard: https://NodeIP:NodePort
例如: https://192.168.150.184:24031
具体参考：docs/guide/dashboard.md

