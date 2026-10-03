# ZEGO 文档 MDX 语法精要（读懂文档必备）

ZEGO 文档是 MDX（Markdown + 组件）。**查阅文档时**主要需要理解三件事：import 内容复用、条件渲染、组件含义。这样才能知道「页面实际会展示什么内容」。

## 一、import 内容复用（跨平台共享文档）

大量平台文档不是独立写的，而是引用另一个平台的文件再按平台过滤：

```mdx
import Content from '/core_products/aiagent/zh/android/quick-start-with-digital-human.mdx'

<Content platform="Web"/>
```

**读文档时的规则**：

1. 文件开头出现 `import X from '/path.mdx'`，而正文只有 `<X />` 或少量补充内容时——**真正的内容在被 import 的文件里**，必须追过去读。
2. `<Content platform="Web"/>` 的 `platform` 属性会传给被引用文件；被引用文件内部的 `:::if{props.platform=...}` 据此决定哪些块生效（见下节）。**读的时候要按当前页面的 platform 值过滤内容**，只关注命中的条件块。
3. import 路径以 `/` 开头时是相对仓库根的绝对路径；`./`、`../../` 是相对当前文件的路径。还有少量 `.jsx` 组件（如 FeatureList）。
4. 被引用文件自己也可能再 import 别的文件（链式复用），逐层追即可。

## 二、条件渲染 `:::if{}`

根据平台/版本条件显示不同内容，是平台差异的主要表达方式：

```mdx
:::if{props.platform="iOS"}
仅 iOS 平台显示的内容。
:::

:::if{props.platform="undefined|iOS|Android"}
本文件所属平台（未被 import 时）、iOS、Android 显示的内容。
:::
```

**规则**：

- 值只能是 **OR 组合**（`|` 分隔），不支持 AND/NOT。
- `undefined` 表示「本文件自身的平台」——文件被直接访问时 props.platform 未定义；被其他文件 import 并传了 platform 时则不是 undefined。判断内容归属时要带上这层语义。
- 不匹配任何 `:::if` 块的内容是无条件显示的公共内容。
- 类似地存在按 SDK 版本等其它 props 的条件块，读法相同。

## 三、常用组件及含义

读文档时把组件「翻译」成语义即可：

| 组件 | 含义/渲染效果 |
|---|---|
| `<Note>` `<Tip>` `<Warning>` `<Error>` | 提示框（注意/建议/警告/错误），`<Callout type="...">` 的快捷写法 |
| `<Tabs>` + `<Tab title="iOS">` | 多平台/多场景切换页签，**只读当前平台那个 Tab** |
| `<Steps>` + `<Step title="...">` | 分步教程（按顺序执行） |
| `<Accordion>` | 折叠的补充详情（默认收起，需要时展开读） |
| `<CardGroup>` + `<Card>` | 导航卡片组（通常是子页面入口） |
| `<Button>` | 按钮/跳转链接 |
| `<Frame>` | 带宽度控制的图片容器（`width="512"` 等） |
| `<Video>` | 视频嵌入（src 为视频地址） |
| `<QRCode>` | 二维码 |
| `<ParamField name="..." prototype="...">` | **API 条目**：一个方法/参数的说明单元，name 是 API 名，锚点由 name 生成 |
| `<CodeGroup>` | 多语言代码切换组（按目标语言读对应代码块） |
| Mermaid 代码块 | 流程图/时序图（```mermaid） |

## 四、增强表格语法

表格表头单元格可带列宽与对齐标注，单元格可标记合并：

```mdx
| 分类-30%-l | 数值-20%-r | 名称-50%-c |   ← 列宽%-对齐(l左/r右/c居中)
|-----------|-----------|-----------|
| 水果      | 100       | 橘子       |
| !mu       | 200       | 苹果       |   ← !mu 表示与上方单元格合并
```

读取时忽略格式标注即可（`-30%-l`、`!mu` 都不是内容）。

## 五、其它语法点

- **代码块**：```` ```objc Podfile ```` 第二个词是文件名提示；高亮标记 `!mark`/`!focus` 出现在行注释里，表示强调，不影响内容。
- **frontmatter**：文件顶部 `---` 块（articleID、date 等）是元数据，跳过。
- **链接**：`[文字](/slug)` 站内链接、`[文字](./xxx.mdx)` 相对链接（多平台复用场景）、`[文字](@apiName)` API 短链（用 `resolve_api_link.sh` 解析）、锚点全小写。
- **HTML 标签**：`<p>`、`<img>`、`<br />` 等原生标签会混用，按 HTML 理解即可。
