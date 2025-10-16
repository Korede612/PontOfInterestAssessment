# 🗺️ POI Finder (UIKit + Core Data + MapKit)

POI Finder is an iOS app built using **UIKit**, **MapKit**, and **Core Data**, designed to help users discover and save nearby Points of Interest (POIs) such as restaurants, cafés, and gas stations.  
It supports **offline mode** using Core Data and features a polished, card-style UI for POI details.

---

## ✨ Features

- 🧭 **Map-based discovery:** Find nearby restaurants, cafés, or gas stations.  
- 🌐 **Online/Offline mode:** Automatically switches to offline data (Core Data) when no network is available.  
- 💾 **Favorites management:** Save and remove favorite places.  
- 🎨 **Polished UI:** Custom map annotation pins and a modern detail view.  
- 🧩 **MVVM architecture:** Clean, maintainable structure.  
- 🧪 **Unit tested:** Includes tests for Core Data and POI search logic.

---

## 🏗️ Project Structure

POIFinder/
│
├── AppDelegate.swift
├── SceneDelegate.swift
│
├── Model/
│   ├── POI.swift
│   ├── PersistenceManager.swift
│   └── POIEntity+CoreData.swift
│
├── View/
│   ├── MapViewController.swift
│   ├── DetailsViewController.swift
│   ├── POIAnnotationView.swift
│   └── CustomAnnotation.swift
│
├── ViewModel/
│   └── POIViewModel.swift
│
├── Utilities/
│   ├── NetworkMonitor.swift
│   └── Extensions.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Info.plist
│   └── LaunchScreen.storyboard
│
├── Tests/
│   └── POIFinderTests.swift
│
└── README.md

---

## ⚙️ Requirements

- iOS 15.0+
- Xcode 15+
- Swift 5.9+
- Core Data enabled

---

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/<yourusername>/POIFinder.git
   cd POIFinder
   ```

2. Open the project:
   ```bash
   open POIFinder.xcodeproj
   ```

3. Run the app in **Xcode Simulator** or on a real device.

---

## 🧩 Core Data Model

The app uses **Core Data** to store:
- POI name  
- Address  
- Latitude  
- Longitude  
- Category (restaurant, café, gas station)

This enables **offline browsing** of saved places.

---

## 🧠 Architecture

- **MVVM pattern**
- **MapKit** for location & POI search
- **Core Data** for persistence
- **Network framework** for online/offline monitoring

---

## 🧪 Unit Testing

Unit tests are located in the `POIFinderTests` target and include:
- Core Data save & fetch validation
- Category filtering
- Offline fallback logic

Run tests in Xcode using `⌘ + U`.

---

## 🖼️ Screenshots (optional)

/Users/Prof_K/Downloads/Screenshot 2025-10-16 at 07.45.46.png

/Users/Prof_K/Downloads/Screenshot 2025-10-16 at 07.43.32.png

---

## 📄 License

MIT License © 2025 'Korede Oko-Osi'
