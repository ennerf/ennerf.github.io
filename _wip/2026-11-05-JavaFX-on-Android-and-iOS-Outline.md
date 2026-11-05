---
title: "JavaFX on Android and iOS — Post Outline (Draft)"
date: 2026-11-05
tags: [JavaFX, GraalVM, Native Image, Android, iOS]
---

Outline for the follow-up to the Raspberry Pi post. Not published until the port is complete and the
repos are public, so every number below gets re-checked at that point. Sources for each fact are in the
workspace notes (`.claude/HEBI-Java/mobile-blog-notes.md` and `mobile-blog-background/`). The earlier
draft `2026-10-22-JavaFX-27-on-Android-and-iOS.adoc` stays as material for the frame timing, touch,
keyboard and motion parts.

Framing that ties the sections together: **getting JavaFX to run on a phone was the small part. Making
it useful means integrating with two platforms, which is more than one person can maintain by hand. It
became affordable by shaping the work so that the correct result was defined before any code was
written.** AI is not in the title and not in the opening. It enters in section 4 as a design constraint,
and the results carry the argument: no speed or volume claims, no model names.

Rules for the draft: no Flutter, no "vs" section, Gluon gets credit only. The partner app appears only
as the source of a missing API. Implementation over showcase.

## 1. Introduction

- Update the Pi post's statement that mobile targets need custom build tools. StaticFX now builds
  JavaFX 27 with a stock Oracle GraalVM into a shared library for Android and iOS.
- The wrapper, stated once here: the app around the library is an ordinary Gradle or Xcode project.
  On Android it is a manifest entry naming the library's `FxActivity`, on iOS a `main.swift` with two
  statements. The library does the rest.
- The claim of the post: a JavaFX app that runs on a phone is not yet a phone app. It needs the
  platform's services and it needs to look and move like the platform.
- The three projects in one line each: StaticFX, the platform mirrors, MobileFX.
- Media: sampler walkthrough video on the Galaxy S20 and the iPhone 14 Pro.

## 2. Getting StaticFX Running

- Same mechanisms as on desktop: routing `System.loadLibrary` to `JNI_OnLoad_<lib>`, deleting the
  natives of the other platforms, and the library lists. No new mechanism was needed.
- One detail worth a sentence: GraalVM's `LINUX` includes Android and `DARWIN` includes iOS, so every
  condition has to name its target.
- Two new artifacts. `jfx-mobile-libs` has the static JavaFX archives and the roughly 180 toolkit
  classes that the published jars lack, since OpenJFX publishes no mobile jars. `jdk-mobile-libs` has
  the static JDK, tied to the exact GraalVM release.
- The jfx fork needed build-file edits only, no product code.
- Credit: the static JDK builds on the openjdk/mobile work by Gluon, and the Pi post describes
  Substrate. One sentence with a link, no comparison.
- Snippet: the three Maven dependencies. Constraint: Android images build on Linux, iOS images on a Mac.
- Honest limits: OpenGL ES only on iOS, no media or web view, arm64 only.

## 3. The Actual Problem: Platform Integration

- What an app needs beyond a window: sensors, Bluetooth, camera, location, files, permissions,
  lifecycle, the keyboard, the safe area, text shaping.
- How the first version did it: one hand-written mapping per service and platform, in C and
  Objective-C, with JNI signature strings that only fail at run time on a device.
- Why that does not scale: two platforms that change every year, and every new app asks for an API
  that is not there yet. Example: a partner app needed a high-speed camera session and Bluetooth,
  neither of which existed.
- Lesson: the amount of code is not the problem, the amount of judgment per line is.

## 4. Working with Agents

- Starting point, stated plainly: agents are cheap at writing code and unreliable at judgment. Code
  that looks right is the default outcome, so "looks right" cannot be the acceptance test.
- Three conditions that made the output trustworthy:
  - a goal that is defined and testable before the work starts
  - as little design space as possible
  - checks that run without a person
- The consequence for the design: move the judgment into something that can be checked. The platform's
  own API specifies a mirror. A measurement on the phone specifies a control. A reference written by
  hand specifies the generator.
- One or two cases where this was missing and what it cost, with the rule that came out of each:
  values picked by eye that had to be redone from measurements, reference files that were edited by
  hand to make a test pass.
- The verification ladder, cheapest first: JVM tests, a desktop native image, one device round.
- Which decisions stayed with a person: API shape, lifetime rules, what counts as a reference.

## 5. Mirroring the Android API

- The goal with no design space: every class has the same name, members, constants and Javadoc as
  the Android class, under a `us.hebi.` prefix. Code written against an Android sample ports by
  changing the imports.
- State early: the mirrors are the output of a deterministic generator and regenerate byte for byte.
  What needs review is the generator and a small runtime, not the generated code.
- Prior art in one sentence: generated platform bindings are an established approach (Kotlin/Native,
  .NET for Android, windows-rs). Verify each before naming it.
- *SDK classes as JNI wrappers.*
  - Snippet: one method of `SensorManager`. Calls go through the `JNIEnv` function table, arguments
    on a stack that is reused per thread.
  - Callbacks: interfaces through a proxy on the ART side, abstract classes through generated
    subclasses.
- *Two garbage collectors.* The part with the most original material.
  - The rule: the two heaps never own each other. The image holds ART objects through global
    references released by `close()`, a scope, or a cleaner. ART holds image objects only through a
    handle.
  - The one possible cycle breaks exactly where Android already requires `close()` or `unregister`,
    so the semantics equal plain Android.
  - What the first review found: local references overflowing at 512 on older ART, a strong
    reference that kept the cycle alive, a nested call that corrupted the argument slot, threads that
    leaked on detach.
  - ART's limit of 51,200 global references and the collection that is nudged below it.
  - Media: one diagram of a call and a callback across the two heaps.
- *NDK headers as C ABI bindings.* Structs as views over caller-owned memory, functions as direct C
  calls. No JNI and no ART on the path, so a sensor sample allocates nothing.
- *Testing.* Table of the four tiers with what each one caught:
  - a reference suite on a small fake SDK that was written by hand first
  - JVM tests against a hosted backend, in milliseconds
  - a desktop native image that starts HotSpot through the invocation API
  - the device
- Costs: fixed size, size per package group, and the one service that was ported from C with its
  before and after. TODO measure the per-call overhead.

## 6. The Same for iOS and macOS

- `objc_msgSend` per signature shape. Delegates are classes created at run time with precompiled
  entry points, since generated upcall stubs are not allowed on an iPhone.
- Retain and release against the image's collector: wrappers retain until closed, and a collected
  wrapper is released on the next call rather than on the cleaner thread.
- macOS shares the headers of the common frameworks, which gives a desktop test of the iOS code.
- Honest difference to Android: method names follow the selectors, so the port is not a pure import
  change.

## 7. Controls That Look Native Through CSS

- Design goal: plain JavaFX code gets the platform's look. `MobileTheme.install()` sets a user-agent
  stylesheet, and stock controls get their platform skin through `-fx-skin`.
- Preference order: CSS only, then a skin, then a new control where JavaFX has none.
- Snippet: the `-fx-skin` line of the progress bar from the SCSS source, and the minimal app.
- One SCSS source for both platforms on top of AtlantaFX, switchable at run time.
- Where the look comes from:
  - iOS: measured on the device from view dumps, screenshots and the Core Animation objects
  - Android: read from the Compose Material 3 source
  - rule: measured values only, and no verdict of "matches native" without saying what was compared
- Inventory in three groups: restyled stock controls, the platforms' own components (navigation,
  sheets, pickers), and the most used community components (avatar, skeleton, pull to refresh,
  one-time code field, photo viewer).
- Motion in one paragraph with the table of fitted springs, pointing to a separate post.
- Media: screenshot table of controls in both themes, light and dark. Side-by-side clips with native.

## 8. Looking Right Is Not Being Right

- The first version of the controls looked good and passed its tests. Underneath it was more complex
  than needed and did a lot of unnecessary work. This is the section that shows what review adds.
- What was wrong, concretely:
  - work in the wrong phase of the pulse, e.g., nodes created during layout that missed the CSS pass
    and showed unstyled for a frame
  - `applyCss()` forced to read a style back, which runs the pass out of order and a second time
  - a region per placeholder where one canvas does it, a CSS pass per call to learn a padding
- Background from ChartFX, where we fixed the same class of problem by hand years ago:
  - the 11.3 layout rework replaced a feedback loop between labels, ranges and layout with a fixed
    sequence per frame: pre-layout, layout, post-layout
  - the lessons carried over: every frame is consistent within itself, no phase runs twice, a scene
    at rest does no work, and nothing gets optimized without instrumentation
- The same split applied to the controls: state and nodes change before the CSS pass, sizes are
  decided in `layoutChildren`, overlays are placed after layout. The remaining exceptions are listed
  in a table with their cost.
- Rendering: which things leave the GPU path in Prism and get rasterized in software every frame.
  Table with frame rates before and after:
  - unequal corner radii
  - shaped regions with a border
  - text above the glyph cache limit
  - shadows on uncached nodes
- Result: 114 to 120 fps on both phones on every sampler page, and no redraws at rest.
- From the earlier draft: pulses from the display's vsync, touch samples with the system's
  timestamps, the keyboard's real curve.
- TODO before claiming "fully GPU accelerated": confirm that the slow-path count is zero on every
  page. Two leftovers were open at the last check.
- TODO before claiming "memory efficient": there is no memory measurement in the notes yet. Measure
  heap and allocation per frame on both phones, or drop the claim.

## 9. Making the API Usable

- The API follows the JavaFX classes people know: overlays with `show`, `hide` and `isShowing`,
  selection as a property instead of a selection model, one `MobileApplication` entry point.
- How it was tested: by writing real apps against it and logging every point of friction. Scope
  Mobile, a Matrix chat client, and the APIs that a partner app was missing.
- Two or three examples of friction and the change that followed.

## 10. Limitations

- From the READMEs at the time of publishing: no web view, no background execution, right-to-left
  unchecked, incomplete screen reader bridge, `TableView` on the stock skin.
- Whatever is still not mirrored.
- Numbers to have by then: library size, cold start, build time.

## 11. Summary

- One paragraph on what exists and one on what the approach needed: a specification for every piece
  and review by someone who knows the framework.
- End on a practical sentence: where the repositories are and how to install the sampler.

## Open Questions

- Name of the UI project in the post: MobileFX, or mobile-platform-ui.
- One post or three. The motion measurements and the mirror lifetime rules each have enough material
  for a post of their own.
- Whether section 8 names the problems as agent output or simply as the first version.
