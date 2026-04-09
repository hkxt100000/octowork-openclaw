# AI 工作记忆 — octowork_openclaw

> 最后更新：2026-04-09

---

## 核心目标

**将 openclaw 的功能直接融合进 octowork-chat，最终只保留一个产品：octowork-chat。**

openclaw 不作为独立产品存在，它的能力成为 octowork-chat 的一部分。

---

## 当前状态

- [ ] 尚未开始融合开发
- [ ] 正在阅读文档、理解两个系统的边界

---

## 已知信息

### octowork-chat
- 现有的主产品，包含前端 dist、后端 server、安装脚本等
- 路径参考：`docs/15-用户版升级手册/octowork-chat/`

### openclaw-node-sdk
- Node.js SDK，提供 openclaw 的核心能力
- 路径：`docs/openclaw-node-sdk/`
- 主要模块：`src/client.ts`, `src/identity.ts`, `src/types.ts`

---

## 待探讨

- openclaw 具体提供哪些能力？（等待查阅文档后补充）
- octowork-chat 后端如何集成 openclaw SDK？
- 前端是否需要新增页面/组件？

---

## 备注

文档存放于 `docs/`，后续分析基于此展开。
