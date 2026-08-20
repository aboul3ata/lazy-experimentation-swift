# Lazy Experimentation for Swift

Lazy Experimentation gives Apple apps local experiment assignment, feature delivery, and outcome capture through Lazy's control plane.

```swift
.package(url: "https://github.com/aboul3ata/lazy-experimentation-swift.git", from: "0.1.1")
```

```swift
import LazyExperimentation

let experiments = try LazyExperimentation(
    clientKey: "lwe_cfg_...",
    subjectID: deviceID,
    attributes: ["plan": "pro"]
)

let enabled = experiments.growthBook.getFeatureValue(
    feature: "new-onboarding",
    as: Bool.self,
    default: false
)

try experiments.capture("onboarding_completed", properties: ["steps": 3])
```
