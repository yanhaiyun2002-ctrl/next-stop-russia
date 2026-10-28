# ADR 0002：布局稳定后才接受激活输入

日期：2026-10-28。状态：P0-02 采纳。

确定性实验已证明：Window/逻辑视口更新后、Control 容器排序前，旧热点仍可触发导航。修复前证据为 `docs/evidence/p0-02/03_diagnostic/resize_probe.json`，而不是将历史跨时刻采样误认为同一帧局部更新。

保留原 Resource、稳定 ID 和导航边界。在现有安全区容器内观察窗口/视口及可见 Control 几何；连续两个过程帧一致后允许激活，并在实际输入时再次校验。按下与松开必须对应同一几何状态；变化时取消，不把旧坐标重定向至新建筑。通过按钮短暂禁用/恢复清除 Godot 的 press-attempt，避免吞掉松开后按钮残留按下。没有导航重放或自动点击重试。

地图同时订阅 Viewport 尺寸及自身可见性变化，确保方向文字、最小尺寸和热点重排都被请求。布局仍使用 Godot 容器与等比缩放，未固定错误的画面。

测试等待可观测几何稳定与导航完成，有 3 秒失败期限；保留原正确性断言。一次合成点击使用同一坐标原子发送 down/up，跨帧持有与跨方向取消单独回归。三建筑快照在一次无 await 的采样中取得，避免把多个导航时刻拼成同一布局。

代价：小型 P0 UI 每帧遍历可见控件，布局变化后短暂停止激活；当前控件数量很少，后续只有真实性能证据要求时再改为事件化。该机制不保证手机真机时序、后台生命周期或任意未来复杂 UI 已验证。

依据：[Godot 4.7 Container](https://docs.godotengine.org/en/4.7/classes/class_container.html)、[SceneTree](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html)、[BaseButton 官方 4.7.2 源码](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/base_button.cpp)。原生窗口历史失败的每个事件序列无法从旧日志完整重建；不宣称五轮通过能排除所有偶发故障。
