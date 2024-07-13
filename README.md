Project Description

This project is a demo two-screen image editing app designed for iOS. The primary screen features a document page displaying a single image. The second screen is the Crop editing screen, where users can perform actions such as cropping, rotating, and flipping the image. The edited result is then saved to the content manager. The project showcases smooth animation transitions between the two screens, regardless of the document's zoom scale and scroll position. Additionally, it includes editing animations, reset animations, and cancel animations.

Architecture and Components

The project is built using the MVVM (Model-View-ViewModel) design pattern. It incorporates multiple custom universal UI elements (lists, dashSlider, cropView, photoView, etc) and structures (cropRect, orientation, axisGeometry, floatLayout, etc).

Features

Smooth Transitions: Demonstrates smooth animation transitions between screens.
Editing Capabilities: Allows users to crop, rotate, and flip the image.
Animation Effects: Includes various editing animations, reset animation, and cancel animation.

Customization and Theming

The project supports multiple themes with automatic color synchronization upon theme updates. All colors can be configured within the KHPalette structure. Additionally, most layout settings such as insets, sizes, and spacings are fully configurable and located within the KHStyle structure.
