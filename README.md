# Lazy Experimentation for Swift

This Swift Package is a thin initializer around GrowthBook's official Apple SDK. GrowthBook owns feature fetching, caching, targeting, hashing, assignment, and exposure callbacks.

```swift
.package(url: "https://github.com/aboul3ata/lazy-experimentation-swift.git", from: "0.1.0")
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

Official engine: [`growthbook-swift`](https://github.com/growthbook/growthbook-swift).
