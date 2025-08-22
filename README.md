# SillyTavern全功能一体化部署脚本（飞牛）

[![GitHub release](https://img.shields.io/github/release/begonia599/sillytavern-one-click-deploy-new.svg)](https://github.com/begonia599/sillytavern-one-click-deploy-new/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

fork from https://github.com/begonia599/sillytavern-one-click-deploy-new  
由于飞牛os自带的nigix占用了8000端口，故将酒馆的端口改为4160：8000
无法测试nigix
使用wget：

```bash
wget https://raw.githubusercontent.com/cvbvbbv/sillytavern-one-click-deploy-new/main/all-in-one-deploy.sh
chmod +x all-in-one-deploy.sh
./all-in-one-deploy.sh
```
