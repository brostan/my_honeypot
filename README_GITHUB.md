# 🐝 Cowrie Honeypot - Complete Setup & Monitoring

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Cowrie](https://img.shields.io/badge/Cowrie-2.9.1-green.svg)](https://github.com/cowrie/cowrie)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen.svg)](https://www.docker.com/)
[![Documentation](https://img.shields.io/badge/docs-Russian-orange.svg)](START_HERE.md)

> 🇷🇺 Complete Cowrie SSH/Telnet Honeypot with automated deployment, monitoring, and comprehensive Russian documentation

![Honeypot Architecture](https://via.placeholder.com/800x200/2C3E50/ECF0F1?text=SSH+%2F+Telnet+Honeypot)

## 🎯 Features

- 🐝 **SSH & Telnet Honeypot** - Capture real-world attacks
- 📊 **Complete Logging** - All commands, sessions, and files
- 🎬 **Session Replay** - Replay attacker sessions
- 📱 **Telegram Alerts** - Real-time notifications
- 🚀 **Automated Deployment** - One-command setup
- 🐳 **Docker Support** - Simple and full stack configurations
- 📚 **Full Documentation** - 88KB+ in Russian
- 🔒 **Security Guidelines** - Production-ready configurations

## 🚀 Quick Start

### Option 1: Docker (Recommended)

```bash
git clone --recurse-submodules https://github.com/brostan/my_honeypot.git
cd my_honeypot
docker-compose -f docker-compose.simple.yml up -d
```

Connect to honeypot:
```bash
ssh -p 2222 root@localhost
```

### Option 2: Automated Deployment

```bash
git clone --recurse-submodules https://github.com/brostan/my_honeypot.git
cd my_honeypot
./deploy.sh
```

### Option 3: Manual Setup

```bash
git clone --recurse-submodules https://github.com/brostan/my_honeypot.git
cd my_honeypot/cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install -e .
./bin/cowrie start
```

## 📚 Documentation

| File | Description | When to Read |
|------|-------------|--------------|
| [START_HERE.md](START_HERE.md) | 🟢 Getting started | Start here |
| [QUICKSTART.md](QUICKSTART.md) | 🟢 5-minute setup | After starting |
| [README.md](README.md) | 🟡 Complete guide | Full documentation |
| [SECURITY.md](SECURITY.md) | 🔴 Security best practices | **Before production!** |
| [MONITORING.md](MONITORING.md) | 🟠 Monitoring & analysis | After deployment |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | 🟡 Project overview | For understanding |

## 🛠️ What's Included

### Scripts
- `deploy.sh` - Automated server deployment
- `scripts/analyze.sh` - Log analysis and statistics
- `scripts/monitor.sh` - Real-time monitoring
- `scripts/backup.sh` - Backup automation

### Docker Configurations
- `docker-compose.yml` - Full stack (Cowrie + ELK + Grafana + Portainer)
- `docker-compose.simple.yml` - Cowrie only (minimal)
- `logstash/pipeline/cowrie.conf` - Log processing for Elasticsearch

### Documentation (Russian)
- Complete setup guide
- Security recommendations
- Monitoring and analysis guide
- Production deployment guide
- 3000+ lines of documentation

## 🎨 Architecture

```
┌─────────────────────────────────────────────┐
│              Internet / Attackers            │
└──────────────────┬──────────────────────────┘
                   │
            ┌──────▼───────┐
            │   Port 22    │  SSH Traffic
            │   Port 23    │  Telnet Traffic
            └──────┬───────┘
                   │
   ┌───────────────▼────────────────┐
   │      Cowrie Honeypot           │
   │  - Logs all commands           │
   │  - Saves downloaded files      │
   │  - Records sessions            │
   └───────────┬────────────────────┘
               │
   ┌───────────▼────────────────────┐
   │   Logging & Visualization      │
   │  • JSON Logs                   │
   │  • Elasticsearch               │
   │  • Kibana                      │
   │  • Grafana                     │
   └────────────────────────────────┘
```

## 📊 What You Can Learn

### Attack Patterns
- Most used passwords
- Common usernames
- Attack sources (countries/IPs)
- Command sequences
- Tools used by attackers

### Threat Intelligence
- Malware samples
- Attack scripts
- IOCs (Indicators of Compromise)
- Attacker behavior patterns

## 🔒 Security Warning

⚠️ **Important**: Honeypots attract malicious actors. Always:

1. ✅ Deploy on isolated VM/VPS
2. ✅ Block outbound traffic
3. ✅ Never on production networks
4. ✅ Read [SECURITY.md](SECURITY.md) before deployment
5. ✅ Monitor all activity

**Recommended**: Use cheap VPS ($5/month) dedicated only for honeypot.

## 📈 Stats

```
📁 Project Statistics
├── Documentation:     7 files (88 KB)
├── Scripts:          8 files
├── Docker configs:   3 files
├── Lines of code:    3000+
└── Status:           ✅ Production Ready
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

- **Cowrie**: BSD-3-Clause License (by Michel Oosterhof)
- **Documentation & Scripts**: MIT License

## 🙏 Acknowledgments

- [Cowrie](https://github.com/cowrie/cowrie) by Michel Oosterhof
- [Cowrie Community](https://www.cowrie.org/slack/)
- All contributors to the honeypot community

## 🔗 Links

- [Cowrie Documentation](https://docs.cowrie.org/)
- [Cowrie GitHub](https://github.com/cowrie/cowrie)
- [Cowrie Slack](https://www.cowrie.org/slack/)

---

**⭐ If you find this project useful, please star it!**

**Made with ❤️ for cybersecurity education and research**

